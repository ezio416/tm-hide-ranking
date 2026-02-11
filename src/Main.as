const string  pluginColor = "\\$F82";
const string  pluginIcon  = Icons::ListOl;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

[Setting hidden]
bool S_Enabled = true;

void Main() {
    auto App = cast<CTrackMania>(GetApp());
    auto Network = cast<CTrackManiaNetwork>(App.Network);
    auto ServerInfo = cast<CTrackManiaNetworkServerInfo>(Network.ServerInfo);

    bool foundStart, foundEnd, goodSequence, paused;
    int start, end;
    string pageName;

    while (true) {
        yield();

        auto Playground = cast<CSmArenaClient>(App.CurrentPlayground);

        if (false
            or App.RootMap is null
            or App.PlaygroundScript is null
            or Playground is null
            or Playground.UIConfigs.Length == 0
            or Network.ClientManiaAppPlayground is null
            or Network.PlaygroundClientScriptAPI is null
            or ServerInfo.CurGameModeStr != "TM_Campaign_Local"
        ) {
            continue;
        }

        foundStart = foundEnd = goodSequence = false;

        switch (Playground.UIConfigs[0].UISequence) {
            case CGamePlaygroundUIConfig::EUISequence::Intro:
            case CGamePlaygroundUIConfig::EUISequence::RollingBackgroundIntro:
            case CGamePlaygroundUIConfig::EUISequence::EndRound:
                goodSequence = true;
        }

        paused = Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed;

        if (true
            and !goodSequence
            and !paused
        ) {
            continue;
        }

        for (int i = Network.ClientManiaAppPlayground.UILayers.Length - 1; i >= 0; i--) {
            CGameUILayer@ Layer = Network.ClientManiaAppPlayground.UILayers[i];
            if (false
                or Layer is null
                or !Layer.IsVisible
                or Layer.LocalPage is null
                or (true
                    and Layer.Type != CGameUILayer::EUILayerType::Normal
                    and Layer.Type != CGameUILayer::EUILayerType::InGameMenu
                )
            ) {
                continue;
            }

            start = Layer.ManialinkPageUtf8.IndexOf("<");
            end = Layer.ManialinkPageUtf8.IndexOf(">");
            if (false
                or start == -1
                or end == -1
                or end <= start + 1
            ) {
                continue;
            }

            pageName = Layer.ManialinkPageUtf8.SubStr(start + 1, end - start - 1);

            if (goodSequence) {
                if (pageName.Contains("Campaign_StartRaceMenu")) {
                    SetFrameVisibility(Layer.LocalPage);
                    foundStart = true;
                    if (foundEnd) {
                        break;
                    }

                } else if (pageName.Contains("Campaign_EndRaceMenu")) {
                    SetFrameVisibility(Layer.LocalPage);
                    foundEnd = true;
                    if (foundStart) {
                        break;
                    }
                }

            } else if (pageName.Contains("Campaign_PauseMenu")) {
                SetFrameVisibility(Layer.LocalPage);
                break;
            }
        }
    }
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}

void SetFrameVisibility(CGameManialinkPage@ Page) {
    auto Frame = cast<CGameManialinkFrame>(Page.GetFirstChild("ComponentRaceMapInfos_frame-rankings"));
    if (Frame !is null) {
        Frame.Visible = !S_Enabled;
    }
}
