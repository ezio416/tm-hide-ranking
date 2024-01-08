// c 2024-01-05
// m 2024-01-05

bool enteringMap = false;
bool running = false;
bool settingChanged = false;
string title = "\\$" + Icons::ListOl + "\\$G Hide Ranking";

[Setting hidden]
bool S_Enabled = true;

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled, !enteringMap)) {
        S_Enabled = !S_Enabled;
        settingChanged = true;
    }
}

void Main() {
    bool inMap;
    bool wasInMap = InMap();

    while (true) {
        inMap = InMap();

        if (inMap) {
            if (!wasInMap)
                OnEnteredMap();
            else if (settingChanged) {
                settingChanged = false;
                startnew(ToggleAllRankingFrames);
            }
        } else if (S_Enabled && !running)
            startnew(ToggleAllRankingFrames);

        wasInMap = inMap;

        yield();
    }
}

bool InMap() {
    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    return App.Editor is null &&
        App.RootMap !is null &&
        App.CurrentPlayground !is null &&
        App.Network !is null &&
        App.Network.ClientManiaAppPlayground !is null;
}

void OnEnteredMap() {
    trace("entering map");

    enteringMap = true;
    startnew(ToggleAllRankingFrames);
}

void ToggleAllRankingFrames() {
    if (running)
        return;

    running = true;

    if (S_Enabled)
        trace("hiding ranking elements" + (!InMap() ? " once map is loaded" : ""));
    else
        trace("showing ranking elements");

    bool wasEnabled = S_Enabled;

    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    CGameManiaAppPlayground@ CMAP;
    while (
        CMAP is null ||
        CMAP.UILayers.Length == 0 ||
        App.RootMap is null ||
        App.CurrentPlayground is null
    ) {
        if (!S_Enabled && wasEnabled) {
            trace("disabled, cancelling operation");
            enteringMap = false;
            running = false;
            return;  // disabled when not in a map, cancel
        }
        try { @CMAP = App.Network.ClientManiaAppPlayground; } catch { }
        yield();  // wait until we're in a map to continue
    }

    CTrackManiaNetworkServerInfo@ ServerInfo;
    try { @ServerInfo = cast<CTrackManiaNetworkServerInfo@>(App.Network.ServerInfo); } catch { }
    if (ServerInfo is null || !ServerInfo.CurGameModeStr.EndsWith("_Local")) {
        trace("ServerInfo is null or we're not playing local, cancelling operation");
        enteringMap = false;
        running = false;
        return;
    }

    CGameUILayer@ StartRaceMenu;
    CGameUILayer@ PauseMenu;
    CGameUILayer@ EndRaceMenu;

    if (enteringMap) {
        enteringMap = false;

        while (CMAP.UI is null || CMAP.UI.UISequence != CGamePlaygroundUIConfig::EUISequence::RollingBackgroundIntro) {
            if (!S_Enabled && wasEnabled) {
                trace("disabled, cancelling operation");
                enteringMap = false;
                running = false;
                return;
            }
            yield();  // wait until StartRaceMenu loads
        }
    }

    while (CMAP.UILayers.Length < 23)
        yield();  // wait in case UI hasn't populated

    for (uint i = 0; i < CMAP.UILayers.Length; i++) {
        if (StartRaceMenu !is null && PauseMenu !is null && EndRaceMenu !is null)
            break;

        CGameUILayer@ Layer = CMAP.UILayers[i];
        if (Layer is null)
            continue;

        string Page = string(Layer.ManialinkPage).Trim().SubStr(26, 22);

        if (Page == "Campaign_StartRaceMenu") {
            @StartRaceMenu = Layer;
            continue;
        }

        if (Page.StartsWith("Campaign_PauseMenu")) {
            @PauseMenu = Layer;
            continue;
        }

        if (Page.StartsWith("Campaign_EndRaceMenu")) {
            @EndRaceMenu = Layer;
            continue;
        }
    }

    if (StartRaceMenu is null) {
        warn("StartRaceMenu null!");
        running = false;
        return;
    }

    if (PauseMenu is null) {
        warn("PauseMenu null!");
        running = false;
        return;
    }

    if (EndRaceMenu is null) {
        warn("EndRaceMenu null!");
        running = false;
        return;
    }

    ToggleRankingFrame(StartRaceMenu.LocalPage);
    ToggleRankingFrame(PauseMenu.LocalPage);
    ToggleRankingFrame(EndRaceMenu.LocalPage);

    trace("success " + (S_Enabled ? "hid" : "show") + "ing ranking elements");

    running = false;
}

void ToggleRankingFrame(CGameManialinkPage@ Page) {
    yield();

    if (Page is null) {
        warn("Page is null!");
        return;
    }

    CGameManialinkFrame@ Frame = cast<CGameManialinkFrame@>(Page.GetFirstChild("ComponentRaceMapInfos_frame-rankings"));

    if (Frame is null)
        warn("Frame is null!");
    else
        Frame.Visible = !S_Enabled;
}