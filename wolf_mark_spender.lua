npcName = "Mark Quartermaster"
wolf_marks = GetItemCount(25)
item_count = math.floor(wolf_marks / 300)
--[[
    Only usage of this is the by pass games "Unique item" capacity in the inventory. 
    Best case I can add a desyn function to it. But meh.
]]
yield(f"/target {npcName}")
yield("/wait 1.0")
yield(f"/interact {npcName}")
yield("/wait 1.0")
yield("/callback InclusionShop true 12 0")
yield("/wait 1.0")
yield("/callback InclusionShop true 13 3")
yield("/wait 1.0")
yield(f"/callback InclusionShop true 14 8 {item_count}")
yield("/wait 1.0")
yield("/callback ShopExchangeItemDialog true 0")
yield("/wait 1.0")
yield("/pcall InclusionShop true 1")
yield("/wait 1.0")