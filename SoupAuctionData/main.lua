local initialQuery
local auctions = {}
DATA = {}

SLASH_SOUPAUCTIONDATA_CACHE1 = '/soupahd'
SLASH_SOUPAUCTIONDATA_REP1 = '/souprep'
LEFT_TO_PROCESS = 0

local function CleanAuctions()
	for i = 1, #auctions do
		if auctions[i] ~= nil then
			table.insert(DATA,auctions[i])
		end
	end
end

local function ScanAuctions(startIndex, stepSize)
	local beginTime = debugprofilestop()
	local continuables = {}
	wipe(auctions)

	print(format("Left: %d",LEFT_TO_PROCESS))

	local i = startIndex
	while i < startIndex+stepSize do
		-- https://github.com/Auctionator/Auctionator/blob/master/Source_Mainline/FullScan/Mixins/Frame.lua
		-- Glitch in Blizzard APIs sometimes items with no item data are returned
    -- Workaround is to ignore them and filter out the nils after the scan is
    -- finished.
		if not C_Item.DoesItemExistByID(auctions[i][17]) then
			LEFT_TO_PROCESS = LEFT_TO_PROCESS - 1
			if LEFT_TO_PROCESS == 0 then
				CleanAuctions()
			end
		elseif not auctions[i][18] then -- hasAllInfo
			local item = Item:CreateFromItemID(auctions[i][17]) -- itemID

			item:ContinueOnItemLoad(function()
				auctions[i] = {C_AuctionHouse.GetReplicateItemInfo(i)}

				LEFT_TO_PROCESS = LEFT_TO_PROCESS - 1
				if LEFT_TO_PROCESS == 0 then
					print(format("Scanned %d auctions in %d milliseconds", #auctions+1, debugprofilestop()-beginTime))
					-- do something with `auctions` or fire some callback
            CleanAuctions()
				end
			end)
		else
			auctions[i] = {C_AuctionHouse.GetReplicateItemInfo(i)}
			LEFT_TO_PROCESS = LEFT_TO_PROCESS - 1
			if LEFT_TO_PROCESS == 0 then
				print(format("Scanned %d auctions in %d milliseconds", #auctions+1, debugprofilestop()-beginTime))
				CleanAuctions()
			end
		end
		i = i + 1
	end

	C_Timer.After(0.01, function()
		ScanAuctions(startIndex+stepSize, stepSize)
	end)
end

local function OnEvent(self, event)
	
end

SlashCmdList["SOUPAUCTIONDATA_CACHE"] = function(msg, editBox)
	local num_items = C_AuctionHouse.GetNumReplicateItems()
	LEFT_TO_PROCESS = num_items
	print(format("Number of Auctions: %d", num_items))

	if num_items == 0 then
		print("Try opening the AH first.")
	else
		ScanAuctions(0,50)
	end
end

SlashCmdList["SOUPAUCTIONDATA_REP"] = function(msg, editBox)
	print("Replicating Items")
	C_AuctionHouse.ReplicateItems()
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
f:SetScript("OnEvent", OnEvent)