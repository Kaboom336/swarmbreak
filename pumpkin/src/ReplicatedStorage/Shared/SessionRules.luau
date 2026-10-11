--!strict
local Rules = {}
function Rules.canWrite(record: any, session: string): boolean
	return type(record) == "table" and record.SessionId == session
end
return Rules
