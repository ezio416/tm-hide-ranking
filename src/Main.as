// c 2024-01-05
// m 2024-01-05

string title = Icons::Trophy + " Hide Ranking";

[Setting category="General" name="Enabled"]
bool S_Enabled = true;

void RenderMenu() {
    if (UI::MenuItem(title, "", S_Enabled))
        S_Enabled = !S_Enabled;
}

bool run = S_Enabled;

void Update(float) {
    if (S_Enabled)
        run = true;

    if (!run)
        return;

    CTrackMania@ App = cast<CTrackMania@>(GetApp());

    CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork@>(App.Network);
    if (Network is null)
        return;

    CTrackManiaNetworkServerInfo@ ServerInfo = cast<CTrackManiaNetworkServerInfo@>(Network.ServerInfo);
    if (ServerInfo is null || !ServerInfo.CurGameModeStr.EndsWith("_Local"))
        return;

    CGameManiaAppPlayground@ CMAP = Network.ClientManiaAppPlayground;
    if (CMAP is null)
        return;

    CGamePlaygroundUIConfig@ Config = CMAP.UI;
    if (Config is null)
        return;

    CGamePlaygroundClientScriptAPI@ ScriptAPI = Network.PlaygroundClientScriptAPI;
    if (ScriptAPI is null)
        return;

    if (
        !ScriptAPI.IsInGameMenuDisplayed &&
        Config.UISequence != CGamePlaygroundUIConfig::EUISequence::EndRound &&
        Config.UISequence != CGamePlaygroundUIConfig::EUISequence::RollingBackgroundIntro
    )
        return;

    CGameUILayer@ StartRaceMenu;
    CGameUILayer@ PauseMenu;
    CGameUILayer@ EndRaceMenu;

    for (uint i = 0; i < CMAP.UILayers.Length; i++) {
        if (StartRaceMenu !is null && PauseMenu !is null && EndRaceMenu !is null)
            break;

        CGameUILayer@ Layer = CMAP.UILayers[i];
        if (Layer is null)
            continue;

        string Page = string(Layer.ManialinkPage).Trim().SubStr(0, 64);

        if (Page.StartsWith("<manialink name=\"UIModule_Campaign_StartRaceMenu")) {
            @StartRaceMenu = Layer;
            continue;
        }

        if (Page.StartsWith("<manialink name=\"UIModule_Campaign_PauseMenu")) {
            @PauseMenu = Layer;
            continue;
        }

        if (Page.StartsWith("<manialink name=\"UIModule_Campaign_EndRaceMenu")) {
            @EndRaceMenu = Layer;
            continue;
        }
    }

    if (StartRaceMenu is null && PauseMenu is null && EndRaceMenu is null) {
        warn("UI layers not found!");
        return;
    }

    ToggleRankingFrame(StartRaceMenu.LocalPage);
    ToggleRankingFrame(PauseMenu.LocalPage);
    ToggleRankingFrame(EndRaceMenu.LocalPage);
}

void ToggleRankingFrame(CGameManialinkPage@ Page) {
    if (Page !is null) {
        CGameManialinkFrame@ Frame = cast<CGameManialinkFrame@>(Page.GetFirstChild("ComponentRaceMapInfos_frame-rankings"));

        if (Frame !is null)
            Frame.Visible = !S_Enabled;
    }

    run = S_Enabled;
}