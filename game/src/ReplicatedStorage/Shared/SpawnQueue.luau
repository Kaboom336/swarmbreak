--!strict
-- Pure FIFO draining used to cap server enemy creation per Heartbeat.

export type Queue<T> = {
	Items: { T },
	First: number,
	Last: number,
	PerFrame: number,
}

local SpawnQueue = {}

function SpawnQueue.new<T>(perFrame: number): Queue<T>
	assert(perFrame >= 1 and perFrame % 1 == 0, "perFrame must be a positive integer")
	return {
		Items = {},
		First = 1,
		Last = 0,
		PerFrame = perFrame,
	}
end

function SpawnQueue.push<T>(queue: Queue<T>, item: T)
	queue.Last += 1
	queue.Items[queue.Last] = item
end

function SpawnQueue.count<T>(queue: Queue<T>): number
	return math.max(0, queue.Last - queue.First + 1)
end

function SpawnQueue.drain<T>(queue: Queue<T>, consume: (T) -> ()): number
	local drained = 0
	while drained < queue.PerFrame and queue.First <= queue.Last do
		local item = queue.Items[queue.First]
		queue.Items[queue.First] = nil
		queue.First += 1
		drained += 1
		consume(item)
	end
	if queue.First > queue.Last then
		queue.First = 1
		queue.Last = 0
	end
	return drained
end

return SpawnQueue
