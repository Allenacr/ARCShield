import networkx as nx
from typing import Dict, Any, List, Optional, Tuple

class EntityGraphService:
    """
    ARCShield Entity Graph Service (F-03, F-11).
    Maintains a multi-relational graph over accounts, devices, UPI handles, and complaints.
    Extracts compact topological features and serializes ego-subgraphs as immutable evidence.
    """
    def __init__(self):
        self.graph = nx.Graph()

    def add_account(self, account_id: str, upi_id: Optional[str] = None, is_flagged: bool = False):
        self.graph.add_node(account_id, type="ACCOUNT", is_flagged=is_flagged)
        if upi_id:
            self.graph.add_node(upi_id, type="UPI_ID", is_flagged=is_flagged)
            self.graph.add_edge(account_id, upi_id, relation="IDENTIFIER_OF")

    def add_device(self, device_id: str, is_flagged: bool = False):
        self.graph.add_node(device_id, type="DEVICE", is_flagged=is_flagged)

    def link_account_device(self, account_id: str, device_id: str):
        self.graph.add_edge(account_id, device_id, relation="USED_ON")

    def add_transaction_edge(self, sender: str, receiver: str, amount: float, timestamp: str):
        self.graph.add_edge(sender, receiver, relation="PAID", amount=amount, timestamp=timestamp)

    def add_complaint(self, complaint_id: str, reported_entity: str, category: str = "CYBER_FRAUD"):
        self.graph.add_node(complaint_id, type="COMPLAINT", category=category, is_flagged=True)
        self.graph.add_node(reported_entity, is_flagged=True)
        self.graph.add_edge(complaint_id, reported_entity, relation="REPORTED_IN")

    def get_compact_features(self, entity_id: str) -> Dict[str, Any]:
        """
        Extract compact numeric features for model consumption (never feed raw graph directly).
        """
        if entity_id not in self.graph:
            return {
                "hops_to_flagged_account": 99,
                "shared_device_count": 0,
                "shared_identifier_count": 0,
                "connected_flagged_accounts": 0,
                "component_size": 1,
                "counterparty_degree_24h": 0,
            }

        # 1. Shortest path to any flagged entity or complaint
        flagged_nodes = [
            n for n, d in self.graph.nodes(data=True)
            if d.get("is_flagged", False) and n != entity_id
        ]

        min_hops = 99
        closest_flagged = None
        for fn in flagged_nodes:
            try:
                path_len = nx.shortest_path_length(self.graph, source=entity_id, target=fn)
                if path_len < min_hops:
                    min_hops = path_len
                    closest_flagged = fn
            except (nx.NetworkXNoPath, nx.NodeNotFound):
                continue

        # 2. Shared device count
        device_neighbors = [
            n for n in self.graph.neighbors(entity_id)
            if self.graph.nodes[n].get("type") == "DEVICE"
        ]
        shared_devices = 0
        for dev in device_neighbors:
            acc_sharing = [
                n for n in self.graph.neighbors(dev)
                if self.graph.nodes[n].get("type") == "ACCOUNT" and n != entity_id
            ]
            shared_devices += len(acc_sharing)

        # 3. Component size & 1-hop degree
        try:
            component = nx.node_connected_component(self.graph, entity_id)
            comp_size = len(component)
        except Exception:
            comp_size = 1

        degree_1hop = self.graph.degree(entity_id)

        # Count flagged accounts in immediate 2-hop neighborhood
        two_hop_nodes = set(nx.single_source_shortest_path_length(self.graph, entity_id, cutoff=2).keys())
        connected_flagged = sum(
            1 for n in two_hop_nodes
            if self.graph.nodes[n].get("is_flagged", False) and n != entity_id
        )

        return {
            "hops_to_flagged_account": min_hops,
            "shared_device_count": shared_devices,
            "shared_identifier_count": 0,
            "connected_flagged_accounts": connected_flagged,
            "component_size": comp_size,
            "counterparty_degree_24h": degree_1hop,
            "closest_flagged_node": closest_flagged,
        }

    def export_subgraph_snapshot(self, center_node: str, radius: int = 2) -> Dict[str, Any]:
        """
        Exports ego-subgraph snapshot around center_node for React Force Graph 2D.
        """
        if center_node not in self.graph:
            return {"nodes": [{"id": center_node, "name": center_node, "type": "UNKNOWN"}], "links": []}

        sub_nodes = set(nx.single_source_shortest_path_length(self.graph, center_node, cutoff=radius).keys())
        subg = self.graph.subgraph(sub_nodes)

        nodes_data = []
        for n in subg.nodes():
            d = subg.nodes[n]
            nodes_data.append({
                "id": str(n),
                "name": str(n),
                "type": d.get("type", "ENTITY"),
                "is_flagged": d.get("is_flagged", False),
                "is_center": (n == center_node),
            })

        links_data = []
        for u, v, d in subg.edges(data=True):
            links_data.append({
                "source": str(u),
                "target": str(v),
                "relation": d.get("relation", "CONNECTED_TO"),
                "amount": d.get("amount"),
            })

        return {
            "center": center_node,
            "radius": radius,
            "nodes": nodes_data,
            "links": links_data,
        }

# Global Singleton
graph_service = EntityGraphService()
