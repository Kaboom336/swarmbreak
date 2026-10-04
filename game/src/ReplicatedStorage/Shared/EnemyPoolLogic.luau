--!strict
-- Pure bookkeeping for the server enemy pool. Instances are supplied by the caller.

export type Pool<T> = {
	Create: (string) -> T,
	Ready: { [string]: { T } },
	Targets: { [string]: number },
}

local EnemyPoolLogic = {}

EnemyPoolLogic.MaxPerRole = 12

function EnemyPoolLogic.new<T>(create: (string) -> T): Pool<T>
	return {
		Create = create,
		Ready = {},
		Targets = {},
	}
end

function EnemyPoolLogic.targetsForComposition(
	composition: { [string]: number },
	rigForRole: (string) -> string?
): { [string]: number }
	local targets = {}
	for role, count in composition do
		local rigKey = rigForRole(role)
		if rigKey then
			targets[rigKey] = math.min(EnemyPoolLogic.MaxPerRole, (targets[rigKey] or 0) + count)
		end
	end
	return targets
end

function EnemyPoolLogic.setTargets<T>(pool: Pool<T>, targets: { [string]: number })
	pool.Targets = table.clone(targets)
end

function EnemyPoolLogic.refill<T>(pool: Pool<T>)
	for rigKey, target in pool.Targets do
		local ready = pool.Ready[rigKey]
		if not ready then
			ready = {}
			pool.Ready[rigKey] = ready
		end
		while #ready < target do
			table.insert(ready, pool.Create(rigKey))
		end
	end
end

function EnemyPoolLogic.trim<T>(pool: Pool<T>, discard: (T) -> ())
	for rigKey, ready in pool.Ready do
		local target = pool.Targets[rigKey] or 0
		while #ready > target do
			discard(table.remove(ready) :: T)
		end
	end
end

function EnemyPoolLogic.take<T>(pool: Pool<T>, rigKey: string): T
	local ready = pool.Ready[rigKey]
	if ready and #ready > 0 then
		return table.remove(ready) :: T
	end
	return pool.Create(rigKey)
end

function EnemyPoolLogic.give<T>(pool: Pool<T>, rigKey: string, entry: T): boolean
	local target = pool.Targets[rigKey] or 0
	local ready = pool.Ready[rigKey]
	if not ready then
		ready = {}
		pool.Ready[rigKey] = ready
	end
	if #ready >= target then
		return false
	end
	table.insert(ready, entry)
	return true
end

return EnemyPoolLogic
