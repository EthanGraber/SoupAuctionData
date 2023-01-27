require "CsvUtils"
local io = require "io"

local initialQuery
local auctions = {}
 
local function ScanAuctions()
	local beginTime = debugprofilestop()
	local continuables = {}
	wipe(auctions)
	for i = 0, C_AuctionHouse.GetNumReplicateItems()-1 do
		auctions[i] = {C_AuctionHouse.GetReplicateItemInfo(i)}
		if not auctions[i][18] then -- hasAllInfo
			local item = Item:CreateFromItemID(auctions[i][17]) -- itemID
			continuables[item] = true

			item:ContinueOnItemLoad(function()
				auctions[i] = {C_AuctionHouse.GetReplicateItemInfo(i)}
				continuables[item] = nil
				if not next(continuables) then
					print(format("Scanned %d auctions in %d milliseconds", #auctions+1, debugprofilestop()-beginTime))
					-- do something with `auctions` or fire some callback
            csv = toCSV(auctions)
            f = io.open("out.csv", "w+")
            io.output(f)
            io.write(csv)
            io.close(f)
				end
			end)
		end
	end
end

local function OnEvent(self, event)
	if event == "AUCTION_HOUSE_SHOW" then
		C_AuctionHouse.ReplicateItems()
		initialQuery = true
	elseif event == "REPLICATE_ITEM_LIST_UPDATE" then
		if initialQuery then
			ScanAuctions()
			initialQuery = false
		end
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
f:SetScript("OnEvent", OnEvent)