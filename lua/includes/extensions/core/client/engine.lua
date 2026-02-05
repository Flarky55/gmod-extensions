local GetAddons = engine.GetAddons


function engine.FindAddon( workshopid )
    local addons = GetAddons()

    for i = 1, #addons do
        local addon = addons[i]
        
        if addon.wsid == workshopid then
            return addon
        end
    end

    return nil
end