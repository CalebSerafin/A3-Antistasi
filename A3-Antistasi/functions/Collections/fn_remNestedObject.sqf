/*
Function:
    A3A_fnc_remNestedObject

Description:
    Recursively deletes nested child objects.
    Can delete self-referencing trees.
    Trying to do this by hand may cause memory leaks.

Scope:
    <LOCAL> Interacts with many objects. Should not be networked.

Environment:
    <SCHEDULED> Recurses over entire sub-tree. Could be resource heavy.

Parameters:
    <VARSPACE/OBJECT> Parent variable space
    <BOOLEAN> Full object purge? Will delete objects as well. [DEFAULT=true]

Returns:
    <BOOLEAN> true if success; false if access denied; nil if crashed;

Examples:
    [[missionNamespace, "A3A_UIDPlayers", "1234567890123456", "equipment", "weapon", "SMG_02_F"] call A3A_fnc_setNestedObject, "helmet", "H_Hat_grey"] call A3A_fnc_setNestedObject;
        // missionNamespace > "A3A_UIDPlayers" > "1234567890123456" > "equipment" > [multiple end values]
    _parent = [missionNamespace, "A3A_UIDPlayers", locationNull] call A3A_fnc_getNestedObject; // returns a <location> that's referenced by "1234567890123456";
    [_parent] call A3A_fnc_remNestedObject;
        // missionNamespace > "A3A_UIDPlayers" <LocationNull>

    // Recursive
    _parent = [missionNamespace, "A3A_parent", "loop back", locationNull] call A3A_fnc_setNestedObject;
    [missionNamespace, "A3A_parent", "recursion", _parent] call A3A_fnc_setNestedObject;
        // missionNamespace > "A3A_parent" > "recursion" > "recursion" > "recursion" > "recursion" > "recursion" > "recursion" > "recursion"...
    [_parent] call A3A_fnc_remNestedObject;
        // missionNamespace > "A3A_parent" <LocationNull>

Author: Caleb Serafin
License: MIT License, Copyright (c) 2019 Barbolani & The Official AntiStasi Community
*/
params [["_parent",locationNull],["_purge",true]];
private _filename = "Collections\fn_remNestedObject.sqf";

[3, ["_parent: ",_parent] joinString "",_filename] call A3A_fnc_log;
[3, ["_purge: ",_purge] joinString "",_filename] call A3A_fnc_log;

if (_parent isEqualType missionNamespace || {isNull _parent}) exitWith {false}; // Deleting all Namespace contents will cause great trouble.
private _childrenNames = allVariables _parent;
private _childrenLocations = [];
private _childrenObjects = [];
private _item = false;
{
    _item = _parent getVariable [_x, false];
    if (_item isEqualType locationNull) then {
        _childrenLocations pushBack _item;
    } else {if (_purge && {_item isEqualType objNull}) then {
        _childrenObjects pushBack _item;
    };};
} forEach _childrenNames;
_childrenNames = nil;  // clear redundant names-list memory before recursing.
deleteLocation _parent;  // Deleting the parent before recursing prevents infinite loop from self-referencing trees.
{
    deleteVehicle _x;
} forEach _childrenObjects;
{
    [_x,_purge] call A3A_fnc_remNestedObject;
} forEach _childrenLocations;
true;