local initialQuery
local auctions = {}
DATA = {}
 
local function ScanAuctions()
	local num_items = C_AuctionHouse.GetNumReplicateItems()
	print(format("Number of Auctions: %d", num_items))

	if num_items == 0 then
		print("Try opening the AH first.")
	end

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
            DATA = auctions
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

SLASH_SOUPAUCTIONDATA1 = '/soupahd'
SlashCmdList["SOUPAUCTIONDATA"] = function(msg, editBox)
	ScanAuctions()
end