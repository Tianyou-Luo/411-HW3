from contextlib import contextmanager
import pytest

from meal_max.models.battle_model import BattleModel
from meal_max.models.kitchen_model import Meal


@pytest.fixture()
def battle_model():
    """Fixture to provide a new instance of BattleModel for each test."""
    return BattleModel()

@pytest.fixture
def mock_update_meal_stats(mocker):
    """Mock the update_meal_stats function for testing purposes."""
    return mocker.patch("meal_max.models.battle_model.update_meal_stats")

"""Fixtures providing sample meals for the tests."""
@pytest.fixture
def sample_meal1():
    return Meal(1, 'Meal 1', 'Cuisine 1', 1.00, 'LOW')

@pytest.fixture
def sample_meal2():
    return Meal(2, 'Meal 2', 'Cuisine 2', 2.00, 'MED')

@pytest.fixture
def sample_battle(sample_meal1, sample_meal2):
    return [sample_meal1, sample_meal2]

@pytest.fixture
def mock_cursor(mocker):
    mock_conn = mocker.Mock()
    mock_cursor = mocker.Mock()

    # Mock the connection's cursor
    mock_conn.cursor.return_value = mock_cursor
    mock_cursor.fetchone.return_value = None  # Default return for queries
    mock_cursor.fetchall.return_value = []
    mock_cursor.commit.return_value = None

    # Mock the get_db_connection context manager from sql_utils
    @contextmanager
    def mock_get_db_connection():
        yield mock_conn  # Yield the mocked connection object

    mocker.patch("meal_max.models.kitchen_model.get_db_connection", mock_get_db_connection)

    return mock_cursor  # Return the mock cursor so we can set expectations per test

##################################################
# Add Battle Management Test Cases
##################################################

def test_prep_combatants(battle_model, sample_battle):
    """Clear all meals from combatants"""
    smple_meal1, smple_meal2 = sample_battle
    battle_model.prep_combatant(smple_meal1)
    battle_model.prep_combatant(smple_meal2)
    assert len(battle_model.combatants) == 2


def test_add_more_combatants_to_filled_list(battle_model, sample_battle):
    """Test error when adding additional meals to a filled up combatants list """
    battle_model.combatants.extend(sample_battle)
    with pytest.raises(ValueError, match="Combatant list is full, cannot add more combatants."):
        battle_model.prep_combatant(sample_battle[0])

##################################################
# Clear Battle Management Test Cases
##################################################

def test_clear_combatants(battle_model, sample_battle):
    """Test clearing all meals from combatants list"""
    smple_meal1, smple_meal2 = sample_battle
    battle_model.prep_combatant(smple_meal1)
    battle_model.prep_combatant(smple_meal2)

    battle_model.clear_combatants()
    assert len(battle_model.combatants) == 0, "Playlist should be empty after clearing"



##################################################
# Battle Retrieval Test Cases
##################################################

def test_get_battle_score(battle_model, sample_meal1):
    """Test successfully retrieves the score of a meal object."""

    retrieved_score = battle_model.get_battle_score(sample_meal1)
    assert retrieved_score== (sample_meal1.price * len(sample_meal1.cuisine)) - 3


def test_get_combatants(battle_model, sample_battle):
    """Test successfully retrieving all combatants(meals) from battle."""
    battle_model.combatants.extend(sample_battle)

    all_combatants = battle_model.get_combatants()
    assert len(all_combatants) == 2
    assert all_combatants[0].id == 1
    assert all_combatants[1].id == 2


##################################################
# Battle Test Cases
##################################################

def test_battle(battle_model, sample_battle, caplog, mocker, mock_cursor):
    """Test battle"""

    # mocker.patch("meal_max.models.battle_model.get_battle_score", side_effect=[85.5, 102.0])
    mocker.patch("meal_max.models.battle_model.get_random", return_value=0.42)
    mocker_update_stats = mocker.patch("meal_max.models.battle_model.update_meal_stats", return_value=None)

    battle_model.combatants.extend(sample_battle)
    winner = battle_model.battle()

    # Assert that combatants has been updated to 1
    assert len(battle_model.combatants) == 1, f"A combatant needs to be removed, since there can only be one winner"

    remaining_meal_names = [combatant.meal for combatant in battle_model.combatants]
    assert winner in remaining_meal_names, f"The winner's meal ({winner}) should remain in the combatants list."
    
def test_battle_insufficient_combatants(battle_model, sample_meal1):
    """Test battle with insufficient combatants"""

    """No Combatants"""
    with pytest.raises(ValueError, match="Two combatants must be prepped for a battle."):
        battle_model.battle()      

    
    """Only 1 Combatant"""
    battle_model.prep_combatant(sample_meal1)
    with pytest.raises(ValueError, match="Two combatants must be prepped for a battle."):
        battle_model.battle() 