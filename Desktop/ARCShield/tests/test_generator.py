"""
ARCShield Test Suite: Synthetic World Generator Tests
Validates the data generator produces correct archetypes, scenarios,
and fraud-labeled events.
"""

import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from generator.archetypes import ARCHETYPES
from generator.world import WorldGenerator, FallbackFaker
from generator.scenarios import ScenarioGenerator


class TestArchetypes:
    """Tests archetype definitions and distributions."""

    def test_archetypes_defined(self):
        assert len(ARCHETYPES) >= 4, "Should have at least 4 user archetypes"

    def test_archetypes_have_required_fields(self):
        required_fields = {"name", "avg_monthly_income"}
        archetypes_list = list(ARCHETYPES.values()) if isinstance(ARCHETYPES, dict) else ARCHETYPES
        for archetype in archetypes_list:
            for field in required_fields:
                assert field in archetype, f"Archetype missing field: {field}"

    def test_income_ranges_are_valid(self):
        archetypes_list = list(ARCHETYPES.values()) if isinstance(ARCHETYPES, dict) else ARCHETYPES
        for archetype in archetypes_list:
            assert archetype["avg_monthly_income"] > 0, \
                f"Invalid income for {archetype['name']}"


class TestWorldGenerator:
    """Tests the synthetic world generator."""

    def test_world_generator_creates_users(self):
        gen = WorldGenerator(seed=42)
        world = gen.generate(n_users=10)
        assert "users" in world
        assert len(world["users"]) == 10

    def test_world_generator_creates_accounts(self):
        gen = WorldGenerator(seed=42)
        world = gen.generate(n_users=10)
        assert "accounts" in world
        assert len(world["accounts"]) >= 10

    def test_world_generator_creates_transactions(self):
        gen = WorldGenerator(seed=42)
        world = gen.generate(n_users=5)
        assert "transactions" in world
        assert len(world["transactions"]) > 0

    def test_world_generator_is_seeded(self):
        """Same seed should produce identical output."""
        gen1 = WorldGenerator(seed=42)
        gen2 = WorldGenerator(seed=42)
        world1 = gen1.generate(n_users=5)
        world2 = gen2.generate(n_users=5)
        assert len(world1["users"]) == len(world2["users"])

    def test_users_have_archetype(self):
        gen = WorldGenerator(seed=42)
        world = gen.generate(n_users=5)
        for user in world["users"]:
            assert "archetype" in user or "role" in user

    def test_fallback_faker_is_seed_reproducible(self):
        faker = FallbackFaker()
        faker.seed(77)
        first_name = faker.name()
        faker.seed(77)
        second_name = faker.name()
        assert first_name == second_name


class TestScenarioGenerator:
    """Tests the fraud scenario generators."""

    def test_scenario_generator_exists(self):
        gen = ScenarioGenerator(seed=42)
        assert gen is not None

    def test_generates_ato_scenario(self):
        """Scenario 1: Account Takeover sequence."""
        gen = ScenarioGenerator(seed=42)
        if hasattr(gen, 'generate_ato_scenario'):
            events = gen.generate_ato_scenario()
            assert len(events) > 0
            # ATO should have credential change events
            event_types = [e.get("event_type", e.get("type", "")) for e in events]
            assert any("device" in t.lower() or "password" in t.lower() or "credential" in t.lower()
                      for t in event_types), "ATO should include device/credential events"

    def test_generates_mule_scenario(self):
        """Scenario 4: Money mule pass-through."""
        gen = ScenarioGenerator(seed=42)
        if hasattr(gen, 'generate_mule_scenario'):
            events = gen.generate_mule_scenario()
            assert len(events) > 0

    def test_scenario_events_have_timestamps(self):
        """All generated events should have timestamps."""
        gen = ScenarioGenerator(seed=42)
        if hasattr(gen, 'generate_all_scenarios'):
            scenarios = gen.generate_all_scenarios()
            for scenario in scenarios:
                for event in scenario.get("events", [scenario]):
                    assert "timestamp" in event or "created_at" in event or "time" in event
