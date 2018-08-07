require'pb.parser'.register_str[[
message cluster
{
message declare {
optional string ptype = 1; 
optional string node  = 2;  
optional string type  = 3;  
optional string addr  = 4;  
}
message question {
optional int32 question = 1;
optional string node     = 2;
}
message answer {
optional int32 answer = 1;
}
message register {
optional string type   = 1;  
optional string addr   = 2;  
optional int32 handle = 3;  
optional string extra  = 4;  
}
message subscribe {
optional string type   = 1;  
optional string addr   = 2;  
}
message update {
message service_t {
optional string   addr   = 1;
optional int32    handle = 2;
optional string   extra  = 3;
}
optional string    mode   = 1;  
optional string    type   = 2;  
repeated service_t list   = 3;  
}
}
message echo {
message req {
optional string  text = 1;
}
message resp {
optional string  text = 1;
}
optional req  rq  = 1;
optional resp rp  = 2;
}
]]