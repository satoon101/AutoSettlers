-- ERA REFERENCE:
--      0 = ERA_ANCIENT
--      1 = ERA_CLASSICAL (turn 61)
--      2 = ERA_MEDIEVAL (turn 121)
--      3 = ERA_RENAISSANCE (turn 181)
--      4 = ERA_INDUSTRIAL (turn 241)
--      5 = ERA_MODERN (turn 301)
--      6 = ERA_ATOMIC (turn 361)
--      7 = ERA_INFORMATION (turn 421)
--      8 = ERA_FUTURE (turn 481)

ANCIENT_ERA_INDEX = GameInfo.Eras["ERA_ANCIENT"].Index
CLASSICAL_ERA_INDEX = GameInfo.Eras["ERA_CLASSICAL"].Index
MEDIEVAL_ERA_INDEX = GameInfo.Eras["ERA_MEDIEVAL"].Index
RENAISSANCE_ERA_INDEX = GameInfo.Eras["ERA_RENAISSANCE"].Index
INDUSTRIAL_ERA_INDEX = GameInfo.Eras["ERA_INDUSTRIAL"].Index
MODERN_ERA_INDEX = GameInfo.Eras["ERA_MODERN"].Index
ATOMIC_ERA_INDEX = GameInfo.Eras["ERA_ATOMIC"].Index
INFORMATION_ERA_INDEX = GameInfo.Eras["ERA_INFORMATION"].Index
FUTURE_ERA_INDEX = GameInfo.Eras["ERA_FUTURE"].Index

SETTLER_INDEX = GameInfo.Units["UNIT_SETTLER"].Index

SKIP_TURN_HASH = GameInfo.UnitOperations["UNITOPERATION_SKIP_TURN"].Hash
SLEEP_HASH = GameInfo.UnitOperations["UNITOPERATION_SLEEP"].Hash

print("=== Auto Settlers (Constants) Loaded ===")
