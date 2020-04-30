db = {}
mission_initialized = false
niod.functions.setMissionDb = function(saved_db)
    if mission_initialized == true then
        return "Error: Mission already initialized"
    end
    db.blue_points = saved_db.blue_points

    iran_ground_templates = {}
    iran_ground_templates["Iran Defense"] = SPAWN:New("Iran Defense")

    db.objective_zones = {}

    db.objective_zones["Capture-Zone"] = {}
    db.objective_zones["Capture-Zone"].zone = "Capture-Zone"
    db.objective_zones["Capture-Zone"].pzone = "Spawn Red"
    db.objective_zones["Capture-Zone"].alive =
        saved_db.objective_zones["Capture-Zone"].alive
    db.objective_zones["Capture-Zone"].name = "Capture-Zone"
    db.objective_zones["Capture-Zone"].zstart = "Spawn Blue"
    db.objective_zones["Capture-Zone"].def_group_name = "Iran Defense"


    local USAConvoy = SPAWN:New("Blue Convoy Group")
    local ConvoyMenuCoalitionBlue = MENU_COALITION:New(coalition.side.BLUE,
                                                       "Manage Convoys")
    local InfoMenuCoalitionBlue = MENU_COALITION:New(coalition.side.BLUE,
                                                     "Mission Information")

    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Mission status",
                               InfoMenuCoalitionBlue, function()
        MESSAGE:New("Blue points: " .. db.blue_points, 15):ToBlue()
    end)

    for key, base in pairs(db.objective_zones) do
        if base.alive == true then
            base.group = iran_ground_templates[base.def_group_name]:SpawnInZone(
                             ZONE_POLYGON:NewFromGroupName(base.pzone))
            base["ZoneCaptureCoalition"] =
                ZONE_CAPTURE_COALITION:New(ZONE:New(base.zone),
                                           coalition.side.RED)
            base["ZoneCaptureCoalition"]:__Guard(1)
            base["ZoneCaptureCoalition"]:Start(30, 30)
            function base.ZoneCaptureCoalition:OnAfterCapture(from, event, to)
                local Coalition = self:GetCoalition()
                MESSAGE:New(base.name .. " captured by blue coalition", 15)
                    :ToAll()
                base.alive = false
            end
            MENU_COALITION_COMMAND:New(coalition.side.BLUE,
                                       "Send Convoy to " .. base.name ..
                                           " (500 points)",
                                       ConvoyMenuCoalitionBlue, function()
                if db.blue_points < 500 then
                    MESSAGE:New("Cannot send convoy to " .. base.name ..
                                    ", you don't have enougth points (500 needed, " ..
                                    db.blue_points .. " gotten) ", 15):ToBlue()
                else
                    USAConvoy:SpawnInZone(ZONE:New(base.zstart))
                        :RouteGroundOnRoad(ZONE:New(base.zone):GetCoordinate(),
                                           80, 1, "On Road")
                    db.blue_points = db.blue_points - 500
                    MESSAGE:New("New Convoy sent to " .. base.name ..
                                    ", points remaining: " .. db.blue_points, 15)
                        :ToBlue()
                end
            end)
        else
            base["ZoneCaptureCoalition"] =
                ZONE_CAPTURE_COALITION:New(ZONE:New(base.zone),
                                           coalition.side.BLUE)
            base["ZoneCaptureCoalition"]:__Guard(1)
            base["ZoneCaptureCoalition"]:Start(30, 30)
            function base.ZoneCaptureCoalition:OnAfterCapture(from, event, to)
                MESSAGE:New(base.name .. " captured by blue coalition", 15)
                    :ToAll()
            end
        end
    end

    iran_sam_templates = {}
    iran_sam_templates["Iran SA-10"] = SPAWN:New("Iran SA-10")
    iran_sam_templates["Iran SA-6"] = SPAWN:New("Iran SA-6")

    db.sam_zones = {}

    db.sam_zones["SA-10-1"] = {}
    db.sam_zones["SA-10-1"].zone = "SA-10-1"
    db.sam_zones["SA-10-1"].def_group_name = "Iran SA-10"
    db.sam_zones["SA-10-1"].alive = saved_db.sam_zones["SA-10-1"].alive

    db.sam_zones["SA-10-2"] = {}
    db.sam_zones["SA-10-2"].zone = "SA-10-2"
    db.sam_zones["SA-10-2"].def_group_name = "Iran SA-10"
    db.sam_zones["SA-10-2"].alive = saved_db.sam_zones["SA-10-2"].alive

    db.sam_zones["SA-10-3"] = {}
    db.sam_zones["SA-10-3"].zone = "SA-10-3"
    db.sam_zones["SA-10-3"].def_group_name = "Iran SA-10"
    db.sam_zones["SA-10-3"].alive = saved_db.sam_zones["SA-10-3"].alive

    db.sam_zones["SA-6-1"] = {}
    db.sam_zones["SA-6-1"].zone = "SA-6-1"
    db.sam_zones["SA-6-1"].def_group_name = "Iran SA-6"
    db.sam_zones["SA-6-1"].alive = saved_db.sam_zones["SA-6-1"].alive

    db.sam_zones["SA-6-2"] = {}
    db.sam_zones["SA-6-2"].zone = "SA-6-2"
    db.sam_zones["SA-6-2"].def_group_name = "Iran SA-6"
    db.sam_zones["SA-6-2"].alive = saved_db.sam_zones["SA-6-2"].alive

    db.sam_zones["SA-6-3"] = {}
    db.sam_zones["SA-6-3"].zone = "SA-6-3"
    db.sam_zones["SA-6-3"].def_group_name = "Iran SA-6"
    db.sam_zones["SA-6-3"].alive = saved_db.sam_zones["SA-6-3"].alive

    sam_sead = SEAD:New({'Iran SA-10', 'Iran SA-6'})

    for key, base in pairs(db.sam_zones) do
        if base.alive == true then
            base.group = iran_sam_templates[base.def_group_name]:SpawnInZone(
                             ZONE:New(base.zone))
            base.set = SET_UNIT:New()
            BASE:E({group = base.group})
            local GroupUnits = base.group:GetUnits()
            for i = 1, #GroupUnits do
                local GroupUnit = base.group:GetUnit(i)
                local UnitName = GroupUnit:GetName()
                local HasRadar = GroupUnit:GetRadar()
                if HasRadar == true then
                    base.set:AddUnitsByName(UnitName)
                    BASE:E("Added to SET " .. UnitName)
                    GroupUnit:HandleEvent(EVENTS.Dead)
                    function GroupUnit:OnEventDead(event)
                        base.set:Remove(UnitName)
                        BASE:E("Removed " .. UnitName .. " from SET")
                        if base.set:Count() <= 0 then
                            base.alive = false
                            MESSAGE:New("SAM GROUP KILLED", 15):ToAll()
                        end
                        MESSAGE:New("SAM RADAR KILLED", 15):ToAll()
                    end
                end
            end
        end
    end

    local IranBlocus = SPAWN:New("Iran Blocus")
    db.iran_blocus = {}

    db.iran_blocus["Iran Blocus 1"] = {}
    db.iran_blocus["Iran Blocus 1"].zone = "Iran Blocus 1"
    db.iran_blocus["Iran Blocus 1"].def_group_name = "Iran Blocus"
    db.iran_blocus["Iran Blocus 1"].alive =
        saved_db.iran_blocus["Iran Blocus 1"].alive

    db.iran_blocus["Iran Blocus 2"] = {}
    db.iran_blocus["Iran Blocus 2"].zone = "Iran Blocus 2"
    db.iran_blocus["Iran Blocus 2"].def_group_name = "Iran Blocus"
    db.iran_blocus["Iran Blocus 2"].alive =
        saved_db.iran_blocus["Iran Blocus 2"].alive

    for key, base in pairs(db.iran_blocus) do
        if base.alive == true then
            base.group = IranBlocus:SpawnInZone(ZONE:New(base.zone))
            base.set = SET_UNIT:New()
            local GroupUnits = base.group:GetUnits()
            for i = 1, #GroupUnits do
                local GroupUnit = base.group:GetUnit(i)
                local UnitName = GroupUnit:GetName()
                local HasRadar = GroupUnit:GetRadar()
                base.set:AddUnitsByName(UnitName)
                BASE:E("Added to SET " .. UnitName)
                GroupUnit:HandleEvent(EVENTS.Dead)
                function GroupUnit:OnEventDead(event)
                    base.set:Remove(UnitName)
                    BASE:E("Removed " .. UnitName .. " from SET")
                    if base.alive == true then
                        base.alive = false
                        BASE:E("Blocus ship killed")
                        MESSAGE:New("Blocus ship killed", 15):ToAll()
                    end
                    MESSAGE:New("Blocus ship killed", 15):ToAll()
                end
            end
        end
    end

    local IranEWR = SPAWN:New("Iran EWR")
    db.iran_ewr = {}

    db.iran_ewr["Iran EWR 1"] = {}
    db.iran_ewr["Iran EWR 1"].zone = "Iran EWR 1"
    db.iran_ewr["Iran EWR 1"].def_group_name = "Iran EWR"
    db.iran_ewr["Iran EWR 1"].alive = saved_db.iran_ewr["Iran EWR 1"].alive

    db.iran_ewr["Iran EWR 2"] = {}
    db.iran_ewr["Iran EWR 2"].zone = "Iran EWR 2"
    db.iran_ewr["Iran EWR 2"].def_group_name = "Iran EWR"
    db.iran_ewr["Iran EWR 2"].alive = saved_db.iran_ewr["Iran EWR 2"].alive

    for key, base in pairs(db.iran_ewr) do
        if base.alive == true then
            base.group = IranEWR:SpawnInZone(ZONE:New(base.zone))
            base.set = SET_UNIT:New()
            BASE:E({group = base.group})
            local GroupUnits = base.group:GetUnits()
            for i = 1, #GroupUnits do
                local GroupUnit = base.group:GetUnit(i)
                local UnitName = GroupUnit:GetName()
                local HasRadar = GroupUnit:GetRadar()
                if HasRadar == true then
                    base.set:AddUnitsByName(UnitName)
                    BASE:E("Added to SET " .. UnitName)
                    GroupUnit:HandleEvent(EVENTS.Dead)
                    function GroupUnit:OnEventDead(event)
                        base.set:Remove(UnitName)
                        BASE:E("Removed " .. UnitName .. " from SET")
                        if base.set:Count() <= 0 then
                            base.alive = false
                            MESSAGE:New("EWR GROUP KILLED", 15):ToAll()
                        end
                        MESSAGE:New("EWR RADAR KILLED", 15):ToAll()
                    end
                end
            end
        end
    end

    DetectionSetGroup = SET_GROUP:New()
    DetectionSetGroup:FilterPrefixes({"Iran EWR"})
    DetectionSetGroup:FilterStart()

    Detection = DETECTION_AREAS:New(DetectionSetGroup, 100000)

    A2ADispatcher = AI_A2A_DISPATCHER:New(Detection)

    A2ADispatcher:SetGciRadius(100000)

    IranBorderZone = ZONE_POLYGON:New("Iran Border",
                                      GROUP:FindByName("Iran Border"))
    A2ADispatcher:SetBorderZone(IranBorderZone)

    A2ADispatcher:SetSquadron("Lar Airbase Squadron",
                              AIRBASE.PersianGulf.Lar_Airbase,
                              {"Iran F-14", "Iran Mig-29"},
                              db.cap_squadron_number)
    A2ADispatcher:SetSquadron("Bandar Abbas Squadron",
                              AIRBASE.PersianGulf.Bandar_Abbas_Intl,
                              {"Iran F-4E", "Iran F-5E", "Iran M21B"},
                              db.gci_squadron_number)

    A2ADispatcher:SetSquadronTakeoffFromParkingCold("Lar Airbase Squadron")
    A2ADispatcher:SetSquadronTakeoffFromParkingCold("Bandar Abbas Squadron")

    A2ADispatcher:SetSquadronLandingAtEngineShutdown("Lar Airbase Squadron")
    A2ADispatcher:SetSquadronLandingAtEngineShutdown("Bandar Abbas Squadron")

    IranCAP = ZONE_POLYGON:New("Iran CAP", GROUP:FindByName("Iran CAP"))
    A2ADispatcher:SetSquadronCap("Lar Airbase Squadron", IranCAP, 7000, 10000,
                                 700, 800, 800, 2500)
    A2ADispatcher:SetSquadronCapInterval("Lar Airbase Squadron", 4, 180, 600)

    A2ADispatcher:SetSquadronGci("Bandar Abbas Squadron", 900, 2000)
end

niod.functions.getMissionDb = function()
    payload = {}
    payload.objective_zones = {}
    for key, base in pairs(db.objective_zones) do
        payload.objective_zones[key] = {}
        payload.objective_zones[key].alive = base.alive
    end
    payload.iran_ewr = {}
    for key, base in pairs(db.iran_ewr) do
        payload.iran_ewr[key] = {}
        payload.iran_ewr[key].alive = base.alive
    end
    payload.sam_zones = {}
    for key, base in pairs(db.sam_zones) do
        payload.sam_zones[key] = {}
        payload.sam_zones[key].alive = base.alive
    end
    payload.iran_blocus = {}
    for key, base in pairs(db.iran_blocus) do
        payload.iran_blocus[key] = {}
        payload.iran_blocus[key].alive = base.alive
    end
    payload.blue_points = db.blue_points
    return payload
end
