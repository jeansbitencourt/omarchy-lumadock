.pragma library

// Visual styles for the dock. Every style provides the same token groups; the
// compositor blur (Hyprland layer rule) is global, so styles only change how much
// of it shows through, via tint alpha. Pixels below the rule's ignore_alpha
// (0.08) are not blurred.
const ids = ["liquid", "frosted", "clear", "solid", "minimal"];
const defaultStyle = "liquid";

// The original look; other styles override only what differs.
const liquid = {
    card: {
        radius: 23,
        borderWidth: 1,
        borderColor: "#45eff8ff",
        body: ["#30232e39", "#3819232e", "#50121b25"],
        highlight: ["#66f8fdff", "#24f8fdff", "#00f8fdff", "#00c5e1f7", "#29c5e1f7"],
        separator: "#55e6f4ff"
    },
    tile: {
        radius: 15,
        hover: "#25eef8ff",
        active: "#537bc9f6",
        activeBorder: "#a7bce7ff",
        indicator: "#adc2d6",
        indicatorActive: "#a5e8ff",
        fallbackBg: "#606d9ab8",
        fallbackText: "#edf7ff"
    },
    tooltip: {
        radius: 9,
        color: "#ef192534",
        border: "#686f8aa4",
        text: "#f1f7ff"
    },
    preview: {
        radius: 15,
        panel: "#fb202c3c",
        border: "#8d7798b6",
        tile: "#34475c",
        tileHover: "#526d89",
        tileBorder: "#596f88",
        tileBorderActive: "#a5e8ff",
        imageArea: "#151e2b",
        closeBg: "#e024303f",
        closeHover: "#a83748",
        closeBorder: "#8799a8b9",
        title: "#f0f7ff"
    },
    settings: {
        radius: 22,
        panel: "#fb223040",
        border: "#667c9bb9",
        text: "#f0f7ff",
        muted: "#c5d7e8",
        disabled: "#8095a9",
        placeholder: "#9eb5ca",
        fieldText: "#eef6ff",
        divider: "#4965798f",
        row: "#6361788d",
        field: "#90131e2a",
        fieldBorder: "#596e8da7",
        fieldBorderActive: "#a786c4ef",
        button: "#303f5264",
        buttonHover: "#66596e85",
        buttonSelected: "#88608aac",
        buttonDown: "#a4507b9f",
        focusRing: "#b3cce8ff"
    }
};

// Merge group by group so a style can override a single token.
function derive(base, overrides) {
    const result = {};
    for (const group of Object.keys(base))
        result[group] = Object.assign({}, base[group], overrides[group] || {});
    return result;
}

const themes = {
    liquid: liquid,

    // Milky, mostly uniform tint over the blur; no specular highlight.
    frosted: derive(liquid, {
        card: {
            borderColor: "#2eeef5ff",
            body: ["#6e3a4655", "#66313c4a", "#70283340"],
            highlight: null,
            separator: "#40e6f0fa"
        },
        tile: {
            hover: "#26eef8ff",
            active: "#4d8fb4d9",
            activeBorder: "#80c8e0f5",
            indicator: "#c3d0dc",
            indicatorActive: "#d2eeff"
        },
        tooltip: { color: "#f2262f3c", border: "#4ab0c4d8" },
        preview: { panel: "#fc2b3745", border: "#52b0c4d8", tile: "#3a4858", tileHover: "#576a7e" },
        settings: {
            panel: "#fc2a3643",
            border: "#52b0c4d8",
            row: "#5c4a5a6b",
            button: "#33485868"
        }
    }),

    // Barely tinted outline. The card sits below the blur rule's ignore_alpha.
    clear: derive(liquid, {
        card: {
            borderColor: "#59eef8ff",
            body: ["#0fffffff", "#0cffffff", "#10ffffff"],
            highlight: null,
            separator: "#40ffffff"
        },
        tile: {
            hover: "#26ffffff",
            active: "#3fffffff",
            activeBorder: "#80ffffff",
            indicator: "#e6f0fa",
            indicatorActive: "#ffffff"
        }
    }),

    // Opaque, flat colour with a subtle edge.
    solid: derive(liquid, {
        card: {
            borderColor: "#2e8aa0b8",
            body: ["#ff1b2530", "#ff1b2530", "#ff1b2530"],
            highlight: null,
            separator: "#40a5b8cc"
        },
        tile: { hover: "#26eef8ff", active: "#667bc9f6", activeBorder: "#a7bce7ff" },
        tooltip: { color: "#ff1b2530", border: "#4d8aa0b8" },
        preview: { panel: "#ff1f2a37", border: "#4d8aa0b8" },
        settings: { panel: "#ff1f2a37", border: "#4d8aa0b8" }
    }),

    // Flat, dark, squarer, no border.
    minimal: derive(liquid, {
        card: {
            radius: 14,
            borderWidth: 0,
            borderColor: "transparent",
            body: ["#d8141a21", "#d8141a21", "#d8141a21"],
            highlight: null,
            separator: "#33ffffff"
        },
        tile: {
            radius: 10,
            hover: "#1affffff",
            active: "#33ffffff",
            activeBorder: "transparent",
            indicator: "#9aa7b4",
            indicatorActive: "#ffffff",
            fallbackBg: "#40ffffff"
        },
        tooltip: { radius: 7, color: "#f2141a21", border: "#26ffffff" },
        preview: { radius: 10, panel: "#fa141a21", border: "#26ffffff", tile: "#262d36", tileHover: "#3a434f", tileBorder: "#3a434f", imageArea: "#0d1116" },
        settings: {
            radius: 14,
            panel: "#fa141a21",
            border: "#26ffffff",
            row: "#4d2a323b",
            field: "#a60d1116",
            fieldBorder: "#40ffffff",
            button: "#2effffff",
            buttonHover: "#4dffffff",
            buttonSelected: "#66ffffff",
            buttonDown: "#80ffffff"
        }
    })
};

function normalizeStyle(id) {
    return ids.includes(id) ? id : defaultStyle;
}

function theme(id) {
    return themes[normalizeStyle(id)];
}

// Alpha channel (0..1) of a #AARRGGBB colour; "transparent" is 0.
function alphaOf(color) {
    if (color === "transparent")
        return 0;
    return /^#[0-9a-f]{8}$/i.test(color) ? parseInt(color.slice(1, 3), 16) / 255 : 1;
}
