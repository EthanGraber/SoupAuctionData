local initialQuery
local auctions = {}
DATA = {}
 
local function ScanAuctions(startIndex, stepSize)
	local beginTime = debugprofilestop()
	local continuables = {}
	wipe(auctions)

	-- https://github.com/Auctionator/Auctionator/blob/master/Source_Mainline/FullScan/Mixins/Frame.lua
	local i = startIndex
	while i < startIndex+stepSize do
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
		i = i + 1
	end

	C_Timer.After(0.01, function()
		self:ScanAuctions(startIndex+stepSize, stepSize)
	end)
end

local function OnEvent(self, event)
	if event == "AUCTION_HOUSE_SHOW" then
		C_AuctionHouse.ReplicateItems()
		initialQuery = true
end

SLASH_SOUPAUCTIONDATA1 = '/soupahd'
SlashCmdList["SOUPAUCTIONDATA"] = function(msg, editBox)
	local num_items = C_AuctionHouse.GetNumReplicateItems()
	print(format("Number of Auctions: %d", num_items))

	if num_items == 0 then
		print("Try opening the AH first.")
	end
	ScanAuctions(0,50)
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
f:SetScript("OnEvent", OnEvent)