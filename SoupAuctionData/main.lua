local is_ah_open = false
auctions = {}
DATA = {}

SLASH_SOUPAUCTIONDATA_CACHE1 = '/soupahd'
SLASH_SOUPAUCTIONDATA_REP1 = '/souprep'
LEFT_TO_PROCESS = 0
TOTAL_ITEMS = 0

local function CleanAuctions()
	print("Started cleaning auctions")
	for key, val in pairs(auctions) do
		if val ~= nil then
			DATA[key] = val
		end
	end
	print("Done cleaning")
end

local function ScanAuctions(startIndex, stepSize)
	print(format("Left: %d",LEFT_TO_PROCESS))

	local i = startIndex
	while i < startIndex+stepSize and LEFT_TO_PROCESS > 0 and i < TOTAL_ITEMS do
		current_item = {C_AuctionHouse.GetReplicateItemInfo(i)}
		-- https://github.com/Auctionator/Auctionator/blob/master/Source_Mainline/FullScan/Mixins/Frame.lua
		-- Glitch in Blizzard APIs sometimes items with no item data are returned
    -- Workaround is to ignore them and filter out the nils after the scan is
    -- finished.
		if not C_Item.DoesItemExistByID(current_item[17]) then
			LEFT_TO_PROCESS = LEFT_TO_PROCESS - 1
			if LEFT_TO_PROCESS <= 0 then
				CleanAuctions()
			end
		elseif not current_item[18] then -- hasAllInfo
			local item = Item:CreateFromItemID(current_item[17]) -- itemID

			item:ContinueOnItemLoad(function()
				auctions[i] = {C_AuctionHouse.GetReplicateItemInfo(i)}

				LEFT_TO_PROCESS = LEFT_TO_PROCESS - 1
				if LEFT_TO_PROCESS <= 0 then
            CleanAuctions()
				end
			end)
		else
			auctions[i] = {C_AuctionHouse.GetReplicateItemInfo(i)}
			LEFT_TO_PROCESS = LEFT_TO_PROCESS - 1
			if LEFT_TO_PROCESS <= 0 then
				CleanAuctions()
			end
		end
		i = i + 1
	end

	if LEFT_TO_PROCESS > 0 then
		C_Timer.After(0.01, function()
			ScanAuctions(startIndex+stepSize, stepSize)
		end)
	end
end

local function OnEvent(self, event, arg1)
	if event == "ADDON_LOADED" then
		if LAST_SCAN_TIME == nil then
			LAST_SCAN_TIME = 0
		end
	elseif event == "AUCTION_HOUSE_SHOW" then
		is_ah_open = true
	elseif event == "AUCTION_HOUSE_CLOSED" then
		is_ah_open = false
	end
end

local function WaitUntilDoneReplicating(prev)
	local n = C_AuctionHouse.GetNumReplicateItems()
	if prev ~= n then
		C_Timer.After(1, function()
			WaitUntilDoneReplicating(n)
		end)
	else
		print("ReplicateItems() done")
		TOTAL_ITEMS = n
		--todo: move /soupahd content here
	end
end

SlashCmdList["SOUPAUCTIONDATA_CACHE"] = function(msg, editBox)
	local num_items = C_AuctionHouse.GetNumReplicateItems()
	LEFT_TO_PROCESS = num_items
	print(format("Number of Auctions: %d", num_items))

	if num_items == 0 then
		print("There was an error replicating items, try /souprep")
	else
		ScanAuctions(0,50)
	end
end

SlashCmdList["SOUPAUCTIONDATA_REP"] = function(msg, editBox)
	-- Make sure the user doesn't burn their 15 minute cooldown by accident
	if not is_ah_open then
		print("Open the AH first!")
		return
	end

	current_time = time()
	if difftime(current_time, LAST_SCAN_TIME) > 15*60 then
		print("Started ReplicateItems()")
		C_AuctionHouse.ReplicateItems()
		LAST_SCAN_TIME = current_time
		WaitUntilDoneReplicating(-1)
	else
		print(format("Too soon! It has only been %d seconds since last scan. You must wait 15 minutes between scans (900 seconds).", difftime(current_time, LAST_SCAN_TIME)))
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("AUCTION_HOUSE_SHOW")
f:RegisterEvent("AUCTION_HOUSE_CLOSED")
f:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", OnEvent)