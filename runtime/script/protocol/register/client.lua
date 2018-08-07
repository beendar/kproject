local REG = require'protocol.host'.register
REG(1, 'Heartbeat', false, false, true)
REG(2, 'SystemError', false, false, true)
REG(3, 'Echo', true, true, true)
REG(4, 'LoginLoginServer', true, true, true)
REG(5, 'RetrieveRegion', true, true, true)
REG(6, 'LoginGameServer', true, true, true)
REG(7, 'ReconnectGameServer', true, true, true)
REG(8, 'UseItem', true, true, true)
REG(9, 'InsertStone', true, true, true)
REG(10, 'SellItem', true, true, true)
REG(11, 'PveBattleBegin', true, true, true)
REG(12, 'PveBattleEnd', true, true, true)
REG(13, 'ExtractCard', true, true, true)
REG(14, 'BattleArray', true, true, true)
REG(15, 'CommittalBegin', true, true, true)
REG(16, 'CommittalEnd', true, true, true)
REG(17, 'SetNickname', true, true, true)
REG(18, 'UpgradeSanctuary', true, true, true)
REG(19, 'FindPlayer', true, true, true)
REG(20, 'MakeFriend', true, true, true)
REG(21, 'MakeFriendForward', true, true, true)
REG(22, 'MakeFriendApply', true, true, true)
REG(23, 'MakeFriendComplete', true, true, true)
REG(24, 'DeleteFriend', true, true, true)
REG(25, 'DeleteFriendForward', true, true, true)
REG(26, 'SendFriendMail', true, true, true)
REG(27, 'RetrieveMailList', true, true, true)
REG(28, 'RetrieveMailContent', true, true, true)
REG(29, 'ReadMail', true, true, true)
REG(30, 'JungleRefresh', true, true, true)
REG(31, 'JungleLevelDown', true, true, true)
REG(32, 'JunglePublish', true, true, true)
REG(33, 'JungleAccept', true, true, true)
REG(34, 'JungleUpdate', true, true, true)
REG(35, 'JungleReward', true, true, true)
REG(36, 'KagutsuRefresh', true, true, true)
REG(37, 'KagutsuSelect', true, true, true)
REG(38, 'KagutsuBattleEnd', true, true, true)
REG(39, 'KagutsuReward', true, true, true)
REG(40, 'KagutsuReset', true, true, true)
REG(41, 'FindFormation', true, true, true)
REG(42, 'MazeGameBegin', true, true, true)
REG(43, 'MazeGameEvent', true, true, true)
REG(44, 'MazeGameEnd', true, true, true)
REG(45, 'ChatJoinRoom', true, true, true)
REG(46, 'ChatSwitchRoom', true, true, true)
REG(47, 'ChatSaying', true, true, true)
REG(48, 'GlobalEvent', true, true, true)
REG(49, 'ClanCreate', true, true, true)
REG(50, 'ClanLogin', true, true, true)
REG(51, 'ClanRetrieveMember', true, true, true)
REG(52, 'ClanEvent', true, true, true)
REG(53, 'ClanRequestJoin', true, true, true)
REG(54, 'ClanHandleJoin', true, true, true)
REG(55, 'ClanQuit', true, true, true)
REG(56, 'ClanSearch', true, true, true)
REG(57, 'ClanRetrieveHistoryEvent', true, true, true)
REG(58, 'ClanKick', true, true, true)
REG(59, 'ClanSetRole', true, true, true)
REG(60, 'ClanWantToBeMaster', true, true, true)
REG(61, 'ClanModifyBaseInfo', true, true, true)
REG(62, 'ClanUpgrade', true, true, true)
REG(63, 'ClanDeleteMessage', true, true, true)
REG(64, 'SetSignature', true, true, true)
REG(65, 'MissionRefresh', true, true, true)
REG(66, 'MissionUpdate', true, true, true)
REG(67, 'MissionReward', true, true, true)
REG(68, 'MallRetrieveList', true, true, true)
REG(69, 'MallBuy', true, true, true)
REG(70, 'DailyBuy', true, true, true)
REG(71, 'GuideEnd', true, true, true)
REG(72, 'PveActionAward', true, true, true)
REG(73, 'DailyChallengeBegin', true, true, true)
REG(74, 'DailyChallengeEnd', true, true, true)
REG(75, 'HousePlay', true, true, true)
REG(76, 'HouseInvite', true, true, true)
REG(77, 'HouseBuy', true, true, true)
REG(78, 'HouseFurnitureSet', true, true, true)
REG(79, 'HouseUpgrade', true, true, true)
REG(80, 'HouseRoleSet', true, true, true)
REG(81, 'KingBattleContext', true, true, true)
REG(82, 'KingBattleSetFormation', true, true, true)
REG(83, 'KingBattleSearch', true, true, true)
REG(84, 'KingBattleRank', true, true, true)
REG(85, 'KingBattleGetFormation', true, true, true)
REG(86, 'KingBattleBegin', true, true, true)
REG(87, 'KingBattleEnd', true, true, true)
REG(88, 'KingBattleAward', true, true, true)
REG(89, 'KingBattleVideo', true, true, true)
REG(90, 'IslandData', true, true, true)
REG(91, 'IslandUpgrade', true, true, true)
REG(92, 'IslandEvent', true, true, true)
REG(93, 'IslandUseDevice', true, true, true)
REG(94, 'IslandGetReward', true, true, true)
require"pb.parser".register_str(
[[
package netprotocol;
message CommittalEndToS {
    required int32 tid = 1;
    required bool  finish = 2;  
}
message CommittalEndToC {
    required int32 tid = 1;
    required int32 status = 2;
    optional bool big = 3; 
    optional int32 tid = 4;
    optional int32 times = 5;
    optional bool chance = 6;
}
message CommittalBeginToS {
    required int32 tid = 1;
    repeated int32 characters = 2;
}
message CommittalBeginToC {
    required int32 tid = 1;
    required int32 status = 2;
    required int32 finish = 3;
    required int32 update = 4;
}
message PveBattleBeginToS {
	
}
message PveBattleBeginToC {
	
}
message GlobalEventToC {
    optional int32 type = 1;     
    optional int32 time = 2;     
    optional string content = 3; 
}
message HouseInviteToS {
}
message HouseInviteToC {
}
message MissionRewardToS {
    optional string type = 1;
    optional int32 mid = 2;
}
message MissionRewardToC {
    optional bool ok = 1;
}
message ClanModifyBaseInfoToS {
    optional string field = 1; 
    optional string value = 2; 
}
message ClanModifyBaseInfoToC {
    
    
    
    optional int32 opcode = 1;
}
message ClanWantToBeMasterToS {
}
message ClanWantToBeMasterToC {
}
message MazeGameBeginToS {
	optional int32 stage = 1; 
	optional int32 map   = 2; 
	repeated int32 team  = 3; 
}
message MazeGameBeginToC {
}
message DailyChallengeBeginToS {
    optional int32 tid = 1; 
    repeated int32 characters = 2; 
}
message DailyChallengeBeginToC {
    optional int32 ok = 1; 
}
message HouseUpgradeToS {
}
message HouseUpgradeToC {
}
message SetSignatureToS {
    optional string sign = 1;
}
message SetSignatureToC {
    optional int32 opcode = 1; 
}
message SystemErrorToC {
	
	
	
	
	
	optional string		reason  = 1;
	
	optional string		message = 2;
}

message tKBRankEntry {
    optional int32 rank = 1;  
    optional string nickname = 2; 
    optional int32 score = 3; 
    repeated int32 formation = 4; 
}
message KingBattleRankToS {
    optional int32 page = 1;
}
message KingBattleRankToC {
    repeated tKBRankEntry list = 1; 
    optional int32 your_rank = 2; 
}
message IslandUseDeviceToS {
    optional int32 tid = 1;
    repeated int32 ext = 2;
}
message IslandUseDeviceToC {
    optional tIslandDevice device = 1;
}
message SendFriendMailToS {
	optional string     reason = 1; 
	optional string     target = 2; 
	
	
}
message SendFriendMailToC {
	optional int32		next_ti = 1; 
}
message ReconnectGameServerToS {
	optional string		pid    = 1;
	optional uint32		secret = 2;  
}
message ReconnectGameServerToC {
	optional bool	ok = 1;
}
message UpgradeSanctuaryToS {
	
	optional int32  role         = 1; 
	optional int32  index        = 2; 
}
message UpgradeSanctuaryToC {
}

message tRegion {
	optional int32		id          = 1; 
	optional string		name        = 2; 
}

message tBase {
	optional string 	pid         = 1;  
	optional int32		rgnid       = 2;  
	optional int32      gensn       = 3;  
	optional int32 		create_time = 4;  
	optional int32 		online      = 5;  
	optional int32		offline     = 6;  
	optional string		nickname    = 7;  
	optional int32		gold        = 8;  
	optional int32		rmb			= 9;  
	optional int32		energy 		= 10; 
	optional uint32		energy_ti	= 11; 
	optional int32		plv         = 12; 
	optional int32      plv_exp     = 13; 
	optional int32		committal_count = 14; 
	optional int32      present_ap_count = 15; 
	optional int32      present_ap_ti    = 16; 
	optional int32      headid           = 17; 
	optional int32      mask             = 18; 
	optional int32		jungle_ti	= 19;	
	optional int32		jungle_exp	= 20;	
	optional int32		jungle_point	= 21;	
	optional int32		jungle_finish_count = 22;
	optional int32      jungle_money_times = 23;
	optional string     clanid = 24; 
	optional int32		kagutsu_open = 25;
	optional int32 		clan_req_ti = 26; 
	optional int32      clan_req_count = 27; 
	optional string		sign = 28; 
	optional int32		guide_id = 29; 
	optional int32      energy_buy_ti = 30; 
	optional int32      energy_buy = 31; 
	optional int32      gold_buy_ti = 32; 
	optional int32      gold_buy = 33; 
	repeated int32		daily_challenge = 34; 
	optional int32		daily_challenge_ti = 35; 
	
	
	optional int32      extract_chance = 36; 
	optional int32      extract_ti = 37; 
}

message tSkill {
	optional int32 		level       = 1; 
}

message tRole {
	optional int32      tid         = 1; 
	optional int32      level       = 2; 
	optional int32      level_exp   = 3; 
	optional int32      awake       = 4; 
	optional int32      awake_exp   = 5; 
	optional int32		quality     = 6; 
	optional int32		quality_exp = 7; 
	optional int32		favour      = 8; 
	optional int32		favour_exp  = 9; 
	optional int32		wisman  	= 10; 
	repeated int32		sanctuary  	= 11; 
	repeated int32      stone       = 12; 
	repeated tSkill		skill       = 13; 
	optional int32		mask		= 14; 
}

message tStone {
	optional int32      sn          = 1; 
	optional int32      tid         = 2; 
	optional int32      level       = 3; 
	optional int32      exp         = 4; 
	optional int32      star        = 5; 
	optional int32      rela        = 6; 
}

message tItem {
	optional int32 		tid         = 1; 
	optional int32      count       = 2; 
}

message tStage {
	optional int32 		tid         = 1; 
	optional int32		used        = 2; 
	optional int32		bought		= 3; 
}

message tPMethod {
	
	optional uint32		methodid    = 1;
	
	
	optional uint32     reset	    = 2; 
	repeated uint32	    unfinished  = 3; 
	repeated tStage 	touched  	= 4; 
	repeated int32      formation   = 5; 
	
	
	optional int32    energy     = 6;  
	optional int32    stage      = 7;  
	optional int32    map        = 8;  
	optional int32    level      = 9;  
	optional int32    x          = 10; 
	optional int32    y          = 11; 
	optional int32    box        = 12; 
	repeated int32    boxLevel   = 13; 
	repeated int32    team       = 14; 
	optional int32    maxstage   = 15; 
	repeated int32    boss       = 16; 
	optional int32    monster    = 17; 
	
	repeated tFurniture zz_fu = 18;
	repeated int32 zz_levels = 19; 
}

message tChapter {
	optional int32      dungeonid   = 1; 
	optional int32		tid			= 2; 
	repeated int32      level       = 3; 
	repeated uint32     action_1    = 4; 
	repeated uint32     action_2    = 5;
	repeated uint32     action_3    = 6;
}

message TemporalInterval {
	required int32	tstart 	= 1;
	required int32	tend		= 2;
}

message tCommittal {
	optional int32      	tid         = 1; 
	optional int32 			status		= 2; 
	optional int32			finish		= 3; 
	optional int32			times		= 4; 
	optional int32			expire		= 5; 
	repeated int32			characters	= 6;
}

message tFriend {
	optional string fpid                = 1;  
	optional int32  status              = 2;  
	optional int32  ap_ti               = 3;  
	
	optional string nickname            = 4;  
	optional int32  headid              = 5;  
	optional int32  mask                = 6;  
	optional int32  plv                 = 7;  
	optional int32  online              = 8;  
	optional int32  offline             = 9;  
	repeated int32  medal               = 10;  
}

message tMail {
	optional string id                  = 1; 
	optional string sender              = 2; 
	optional int32  sendtime            = 3; 
	optional int32  expire              = 4; 
	optional string title               = 5; 
	optional string content             = 6; 
	optional string attachment          = 7; 
	optional bool   read                = 8; 
	optional int32  texttype            = 9; 
	optional int32  priority            = 10; 
	
	
	
	
}

message tJungle {
	optional int32 	sn = 1;	
	optional int32 	tid = 2;			
	optional int32 	current = 3;		
	optional string pid = 4;		
	optional string accept = 5;		
	optional int32 	status = 6;		
	optional int32 	expire = 7;		
	optional bool   got_reward = 8; 
	optional bool   got_money = 9; 
}
message tKagutsuCharacter {
	optional int32 tid = 1;
	optional int32 line = 2;
	optional int32 hp	= 3;
	optional int32 idx  = 4;
}

message tKagutsu {
	optional int32	tid = 1;
	repeated int32 line_pos = 2;
	repeated int32 got_reward = 3;
	repeated tKagutsuCharacter characters = 4;
}

message tClanBase {
	optional string clanid = 1;   
	optional string masterid = 2; 
	optional string name = 3;     
	optional int32  level = 4;    
	optional int32  icon = 5;     
	optional int32  gold = 6;     
	optional int32  medal = 7;    
	optional string sign = 8;     
	optional int32  score = 9;    
	optional int32  mbrs = 10;    
}

message tClanMember {
	
	optional string pid      = 1;     
	optional int32  role     = 2;     
	optional int32  score    = 3;     
	optional int32  medal    = 4;     
	
	optional tBase base      = 5;     
}
message tMission {
	optional int32 	mid = 1;			
	optional int32 	value = 2;			
	optional bool 	got_reward = 3;
	optional int32 	expire = 4;
	optional bool 	complete = 5;		
	optional string type = 6;
}

message tFurniture {
	optional int32 posx = 1;     
	optional int32 roomid = 2;  
	optional int32 uid = 3;     
	optional int32 tid = 4;     
	optional int32 state = 5;   
	optional int32 count = 6;   
	optional int32 posy = 7;     
	optional int32 rotate = 8;   
}

message tHouseRole {
	optional int32 tid = 1;      
	optional int32 start_ti = 2; 
	optional int32 state = 3;    
}

message tKBPlayer {
	
	
	optional int32 plv = 1; 
	optional string nickname = 2; 
	optional int32 tid = 3; 
	optional bool beat = 4; 
}

message tKBContext {
	
	
	optional int32 finish_ti = 1;       
	optional int32 refresh_ti = 2;      
	optional int32 won = 3;             
	optional int32 score = 4;           
	repeated int32 formation_atk = 5;   
	repeated int32 formation_def = 6;   
	repeated tKBPlayer enemies = 7;     
}
message tIslandDevice {
	optional int32 tid = 1;		
	optional int32 level = 2;	
	optional int32 action = 3;	
	optional int32 expire = 4;	
	repeated int32 events = 5;	
	repeated int32 ext = 6;		
}
message MakeFriendToS {
	optional string     target = 1; 
}
message MakeFriendToC {
}
message ClanEventToC {
    optional int32 type = 1;     
    optional int32 time = 2;     
    optional string content = 3; 
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
	
	
	
}
message ChatJoinRoomToS {
	optional int32	channel = 1; 		
}
message ChatJoinRoomToC {
    optional int32	opcode  = 1; 	
	optional int32	secret  = 2;     
	optional string	host    = 3;  	
	optional string pid     = 4;     
}
message ClanQuitToS {
}
message ClanQuitToC {
}
message HouseBuyToS {
	optional int32 tid = 1;      
	optional int32 count = 2;    
}
message HouseBuyToC {
	optional int uid = 1;    
}
message HeartbeatToS {
}
message HeartbeatToC {
}
message PveActionAwardToS {
    optional int32 actionid = 1; 
    optional int32 diffculty = 2; 
    optional int32 awardindex = 3; 
}
message PveActionAwardToC {
}

message MakeFriendApplyToS {
	optional string 	source = 1; 
	optional bool       ok     = 2; 
}
message MakeFriendApplyToC {
}
message ChatSayingToS {
	optional string	pid     = 1;    
	optional string	content = 2;    
	optional int32  secret  = 3;    
}
message ChatSayingToC {
	optional string	pid      = 1;    
	optional string nickname = 2;    
	optional int32  headid   = 3;    
	optional int32  plv      = 4;    
	optional string	content  = 5;    
	optional int32  time     = 6;    
}
message KingBattleEndToS {
    optional bool won = 1;
}
message KingBattleEndToC {
    optional int32 score = 1;       
    optional int32 score_incre = 2; 
    optional int32 coin = 3;        
    optional int32 energy = 4;      
    optional int32 player_exp = 5;  
    optional int32 role_exp = 6;    
}
message KingBattleVideoToS {
}
message KingBattleVideoToC {
}
message LoginLoginServerToS {
	optional int32		type  = 1;	
	optional string		token = 2; 
	optional string		password = 3;	
	optional string		activation_code = 4; 
	optional int32		nonce = 5; 
	optional int32		os    = 6;	
	optional int32		platform = 7;	
	optional int32		version = 8;	
}
message LoginLoginServerToC {
	optional string		pid    = 1;	  
	optional string		host   = 2;   
	optional int32      secret = 3;   
	optional int32		opcode  = 4;		
}
message KingBattleBeginToS {
}
message KingBattleBeginToC {
}
message KagutsuRewardToS {
    optional int32 tid = 1;
}
message KagutsuRewardToC {
    optional tKagutsu kagutsu = 1;
}
message ChatSwitchRoomToS {
}
message ChatSwitchRoomToC {
}
message RetrieveMailContentToS {
	optional string		id = 1; 
}
message RetrieveMailContentToC {
	optional string 	content = 2; 
}
message IslandGetRewardToS {
    optional int32 tid = 1;
}
message IslandGetRewardToC {
    optional tIslandDevice device = 1;
}
message DailyBuyToS {
    optional string type = 1; 
}
message DailyBuyToC {
    optional int32  value = 1;   
    optional int32  next_ti = 2; 
}
message IslandEventToS {
}
message IslandEventToC {
}
message BattleArrayToS {
	optional int32 type  = 1; 
	repeated int32 array = 2; 
}
message BattleArrayToC {
}
message ClanKickToS {
    optional string target = 1; 
}
message ClanKickToC {
    
    
}
message SetNicknameToS {
	optional string     nn = 1; 
}
message SetNicknameToC {
	optional int32      opcode = 1; 
}
message ClanCreateToS {
    optional string name = 1;       
    optional string sign = 2;       
    optional int32  icon = 3;       
}
message ClanCreateToC {
    
    
    
    optional int32 opcode = 1; 
}
message EchoToS {
	optional string		text = 1;
}
message EchoToC {
	optional string		text = 1;
}
message GuideEndToS {
    required int32 gid = 1; 
}
message GuideEndToC {
    optional bool ok = 1; 
}
message HouseFurnitureSetToS {
}
message HouseFurnitureSetToC {
}
message ClanDeleteMessageToS {
}
message ClanDeleteMessageToC {
}
message DeleteFriendForwardToC {
    optional string     fpid = 1;
}
message DeleteFriendToS {
	optional string    target = 1; 
}
message DeleteFriendToC {
}
message KagutsuResetToS {
}
message KagutsuResetToC {
    optional int32 result = 1;
}
message JunglePublishToS {
    optional int32 sn = 1;
}
message JunglePublishToC {
    optional int32 status = 1;
    optional int32 expire = 2;
}
message ClanUpgradeToS {
}
message ClanUpgradeToC {
    optional bool ok = 1; 
}
message ClanSetRoleToS {
    optional string target = 1;
    optional int32  role = 2;
}
message ClanSetRoleToC {
    optional bool ok = 1; 
}
message ClanRequestJoinToS {
    optional string clanid = 1; 
}
message ClanRequestJoinToC {
    optional bool ok = 1; 
}
message ClanHandleJoinToS {
    optional string target = 1; 
    optional bool ok = 2; 
}
message ClanHandleJoinToC {
    optional string clanid = 1; 
}
message HouseRoleSetToS {
}
message HouseRoleSetToC {
}
message KingBattleSetFormationToS {
    optional int32 type = 1; 
    repeated int32 formation = 2;
}
message KingBattleSetFormationToC {
}
message HousePlayToS {
}
message HousePlayToC {
}
message InsertStoneToS {
	
	optional int32  position     = 1; 
	optional int32  stone        = 2; 
	optional int32  role         = 3; 
}
message InsertStoneToC {
	
}
message JungleUpdateToS {
    optional string pid = 1;
    optional int32 sn = 2;
    optional int32 add = 3;
}
message JungleUpdateToC {
    optional bool ok = 1;
    optional tJungle jungle = 2;
}
message JungleRewardToS {
    optional string pid = 1;
    optional int32 sn = 2;
}
message JungleRewardToC {
    optional bool ok = 1;
    optional int32 reward = 2;
    optional int32 money = 3;
}
message KingBattleSearchToS {
}
message KingBattleSearchToC {
    optional int32 refresh_ti = 1;
    repeated tKBPlayer enemies = 2;
}
message UseItemToS {
	repeated tItem  items    = 1; 
	optional uint32 type     = 2; 
	optional int32  role     = 3; 
	optional int32  stone    = 4; 
}
message UseItemToC {
	repeated tSkill 	skill = 1; 
	repeated tItem 	    item = 2;  
	repeated tStone     stone = 3; 
	optional int32      energy = 4; 
}
message KingBattleContextToS {
    
    
    
    optional int32 type = 1;
}
message KingBattleContextToC {
    
    optional tKBContext ctx = 1;
    
    optional int32 score = 2;
}
message IslandUpgradeToS {
    optional int32 tid = 1;
}
message IslandUpgradeToC {
    optional tIslandDevice device = 1;
}
message KagutsuRefreshToS {
}
message KagutsuRefreshToC {
    optional tKagutsu kagutsu = 1;
}
message KagutsuBattleEndToS {
    optional int32 sid = 1;
    repeated tKagutsuCharacter characters = 2;
}
message KagutsuBattleEndToC {
    optional tKagutsu kagutsu = 1;
}
message HouseVisitToS {
	
	optional int32 visit = 1;   
}
message HouseVisitToC {
	repeated tFurniture furs = 1;  
	repeated tHouseRole roles = 2; 
}
message KingBattleGetFormationToS {
    optional int32 indexofenemy = 1; 
}
message KingBattleGetFormationToC {
    repeated tRole role = 1;
    repeated tStone stone = 2;
}
message ClanRetrieveMemberToS {
    optional int32 page = 1; 
    optional string clanid = 2; 
}
message ClanRetrieveMemberToC {
    optional int32 page = 1; 
    optional string clanid = 2; 
    repeated tClanMember member = 3; 
}
message MissionUpdateToS {
    repeated tMission mission = 1;
}
message MissionUpdateToC {
}
message ExtractCardToS {
	optional int32	count = 1; 
}
message ExtractCardToC {
	repeated tRole	role = 1; 
	repeated tItem  item = 2; 
	repeated int32  roleidlist = 3; 
}
message JungleLevelDownToS {
    optional int32 sn = 1;
}
message JungleLevelDownToC {
    optional tJungle jungle = 1;
}
message RetrieveRegionToS {
	optional int32 	nonce = 1;
}
message RetrieveRegionToC {
	repeated tRegion region = 1;
}
message MallRetrieveListToS {
    optional int32 id = 1;  
    optional bool forcely = 2; 
}
message MallRetrieveListToC {
    repeated int32 list = 1;        
    repeated int32 bought = 2;      
    optional int32 refresh_ti = 3;  
}
message FindFormationToS {
	optional string	target = 1;
}
message FindFormationToC {
	repeated tRole role = 1;
	repeated tStone stone = 2;
}
message FindPlayerToS {
	optional string		target = 1; 
}
message FindPlayerToC {
	
	
	optional tBase	base = 1; 
}
message JungleRefreshToS {
    optional bool need_get = 1;  
}
message JungleRefreshToC {
    repeated tJungle jungle = 1;
    repeated tJungle published = 2;
}
message MissionRefreshToS {
}
message MissionRefreshToC {
    repeated tMission normal = 1;
    repeated tMission activity = 2;
    repeated tMission weekly = 3;
    repeated tMission daily = 4;
    optional int32 daily_point = 5;
    optional int32 weekly_point = 6;
    optional int32 daily_et = 7;
    optional int32 weekly_et = 8;
    repeated int32 complete = 9;
    repeated int32 daily_point_reward = 10;
    repeated int32 weekly_point_reward = 11;
}
message ReadMailToS {
	optional string		id = 1; 
}
message ReadMailToC {
	
	optional int32		rmb  = 1;   
	optional int32		gold = 2;   
	optional int32		energy = 3; 
	repeated tItem      item = 4;   
	repeated tStone 	stone = 5;  
}
message MazeGameEndToS {
    optional bool perfect = 1; 
}
message MazeGameEndToC {
    repeated tItem  item  = 1;
    repeated tStone stone = 2;
}
message KagutsuSelectToS {
    optional int32 tid = 1;
}
message KagutsuSelectToC {
    optional tKagutsu kagutsu = 1;
}

message MakeFriendForwardToC {
	optional tFriend 	friend = 1; 
}
message IslandDataToS {
    
}
message IslandDataToC {
    repeated tIslandDevice devices = 1;
}
message MallBuyToS {
    optional int32 shopid = 1; 
    optional int32 goodsid = 2; 
}
message MallBuyToC {
    repeated tItem item = 1;
    repeated tStone stone = 2;
}
message LoginGameServerToS {
	optional string		pid    = 1;	
	optional uint32     rgnid  = 2; 
	optional uint32     secret = 3; 
}
message LoginGameServerToC {
	optional uint32		opcode      = 1; 
	optional string		pid    		= 2; 
	optional uint32     secret 		= 3; 
	optional tBase      base   		= 4; 
	repeated tRole      role   		= 5; 
	repeated tStone     stone  		= 6; 
	repeated tItem      bag    		= 7; 
	repeated tChapter   chapter 	= 8; 
	repeated tPMethod	pmethod 	= 9; 
	repeated tCommittal	committal 	= 10; 
	repeated tFriend    friend      = 11; 
}
message ClanRetrieveHistoryEventToS {
    optional int32 type = 1; 
}
message ClanRetrieveHistoryEventToC {
    repeated ClanEventToC   history = 1; 
}
message PveBattleEndToS {
	optional int32		stageid			= 1; 
	optional int32      star            = 2; 
	optional bool		won             = 3; 
	repeated int32      team            = 4; 
}
message PveBattleEndToC {
	
	
	
	
	
	
	
	
	
	
	optional int32		cur_diffculty_nextstageid   = 1; 
	optional int32		next_diffculty_firststageid = 2; 
	optional tChapter   next_chapter                = 3;
	
	
	repeated tItem		item                        = 4;   
	repeated tStone     stone                       = 5;   
}
message MazeGameEventToS {
	
	
	
	
	
	
	
	optional int32 method   = 1; 
	optional int32 box      = 2; 
	optional int32 boxLevel = 3; 
	optional int32 x         = 4; 
	optional int32 y         = 5; 
	optional int32 map      = 7; 
	optional bool  won      = 8; 
	optional int32 boss     = 9; 
	optional int32 monster  = 10; 
}
message MazeGameEventToC {
}
message KingBattleAwardToS {
    optional int32 stage = 1;
}
message KingBattleAwardToC {
    repeated tItem item = 1; 
}

message MakeFriendCompleteToC {
	optional tFriend 	friend = 1; 
}
message RetrieveMailListToS {
}
message RetrieveMailListToC {
	repeated tMail	mails = 1; 
}
message ClanLoginToS {
}
message ClanLoginToC {
    optional tClanBase clanbase = 1; 
}
message DailyChallengeEndToS {
    optional int32 tid = 1; 
}
message DailyChallengeEndToC {
    optional int32 ok = 1; 
    repeated tItem rewards = 2;
}
message JungleAcceptToS {
    optional string pid = 1;
    optional int32 sn = 2;
}
message JungleAcceptToC {
    optional bool ok = 1;
    optional tJungle jungle = 2;
}
message ClanSearchToS {
    
    
    
    
    optional int32 type = 1;     
    
    
    
    optional string variant = 2; 
}
message ClanSearchToC {
    repeated tClanBase clanbase = 1; 
}
message SellItemToS {
	repeated tItem  items    = 1; 
	repeated uint32 stones    = 2; 
}
message SellItemToC {
	optional uint32 gold     = 1; 
}
]]
, "protocol.host" )