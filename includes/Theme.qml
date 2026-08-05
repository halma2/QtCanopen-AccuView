import QtQuick
import QtGraphs // Qt 6.11

Item {
    id: themeSettingsRoot

    property string borderColor: "#3f3f46"
    property string buttonBackgroundColor: "#ffffff"
    property string buttonHighlightedColor: "#cccccc"
    property string buttonPressedColor: "#aaaaaa"
    property string diagramSwipeBackgroundColor: "#ffffff"
    property string groupSwipeBackgroundColor: "#ffffff"
    property string paneBackgroundColor: "#ffffff"
    property string sideBarBackgroundColor: "#fffff0"
    property string sidePanelBackgroundColor: "#ffffff"
    property string swipeStepButtonColor: "#000000"
    property int fontPixelSize: 28
    property string graphBackgroundColor: graph_theme.backgroundColor
    property bool isMinMaxplot: false
    property alias projectPalette: internalPalette
    property alias graphTheme: graph_theme

    Palette {
        id: internalPalette

        base: "#ffffff" // spinbox háttér
        button: "#ffffff"
        buttonText: "#000000"
        highlight: "#0000ff" // tab-bal kijelölt gombok kerete
        text: "#000000"
        window: "#fffff0"
        windowText: "#000000"
    }
    GraphsTheme {
        id: graph_theme

        axisXLabelFont.pixelSize: themeSettingsRoot.fontPixelSize
        axisY.mainColor: "#ccccff"
        axisY.subColor: "#eeeeff"
        axisYLabelFont.pixelSize: themeSettingsRoot.fontPixelSize
        backgroundColor: "#fffff0"
        borderColors: ["#807040", "#706030"]
        colorScheme: GraphsTheme.ColorScheme.Light
        grid.mainColor: "#ccccff"
        grid.subColor: "#eeeeff"
        labelTextColor: "#000000"
        seriesColors: isMinMaxplot ? ["#00ffffff", "#E0D080"] : ["#E0D080", "#00F0FF"]
    }
}
