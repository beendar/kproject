local t = {

    PMETHOD_DUNGEON  = 1,
    PMETHOD_FOGMAZE  = 2,

    PDUNGEON_MAIN    = 1,
    PDUNGEON_DAILY   = 2,
    PDUNGEON_VERSUS  = 3,
    PDUNGEON_KING    = 4,

    DIFFCULTY_NORMAL = 1,
    DIFFCULTY_HARD   = 2,
    DIFFCULTY_MAX    = 3,
    DIFFCULTY_CLEAR  = 0xDEAD,

    STARMAX   = 7, -- in binary bits [[2]:1,[1]:1,[0]:1]
    STARSHIFT = 65536,

}


require 'metadata'.new('constant', t)