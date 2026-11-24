import QtQuick

Item {
    id: root

    property url source: ""
    readonly property bool ready: icon.status === Image.Ready
    property bool analyzed: false
    property size analyzedSize: Qt.size(128, 128)
    property rect contentRect: Qt.rect(0, 0, 128, 128)
    property url requestedSource: ""

    readonly property real sourceScale: analyzed && analyzedSize.width > 0 && analyzedSize.height > 0
        ? Math.min(width / analyzedSize.width, height / analyzedSize.height) : 0
    readonly property real visibleContentWidth: contentRect.width * sourceScale
    readonly property real visibleContentHeight: contentRect.height * sourceScale
    readonly property real normalizedScale: analyzed && visibleContentWidth > 0 && visibleContentHeight > 0
        ? Math.min(width / visibleContentWidth, height / visibleContentHeight) : 1
    readonly property real contentCenterOffsetX: analyzed
        ? (contentRect.x + contentRect.width / 2 - analyzedSize.width / 2) * sourceScale : 0
    readonly property real contentCenterOffsetY: analyzed
        ? (contentRect.y + contentRect.height / 2 - analyzedSize.height / 2) * sourceScale : 0

    clip: true

    function analyzeSource() {
        if (requestedSource === source && (!source || analyzer.isImageLoaded(source)
                || analyzer.isImageLoading(source) || analyzer.isImageError(source)))
            return;

        analyzed = false;
        analyzedSize = Qt.size(128, 128);
        contentRect = Qt.rect(0, 0, 128, 128);
        requestedSource = source;
        if (requestedSource)
            analyzer.loadImage(requestedSource, Qt.size(128, 128));
    }

    onSourceChanged: analyzeSource()
    Component.onCompleted: analyzeSource()

    Canvas {
        id: analyzer
        width: 1
        height: 1
        visible: true
        opacity: 0.001
        contextType: "2d"

        function analyzePixels() {
            const loaded = root.requestedSource && analyzer.isImageLoaded(root.requestedSource);
            if (!available || !context || !root.requestedSource || root.requestedSource !== root.source
                    || root.analyzed || !loaded)
                return;

            let pixels;
            try {
                pixels = context.createImageData(String(root.requestedSource));
            } catch (error) {
                return;
            }
            if (!pixels || pixels.width < 1 || pixels.height < 1)
                return;

            let minX = pixels.width;
            let minY = pixels.height;
            let maxX = -1;
            let maxY = -1;
            for (let y = 0; y < pixels.height; y++) {
                for (let x = 0; x < pixels.width; x++) {
                    if (pixels.data[(y * pixels.width + x) * 4 + 3] <= 16)
                        continue;
                    minX = Math.min(minX, x);
                    minY = Math.min(minY, y);
                    maxX = Math.max(maxX, x);
                    maxY = Math.max(maxY, y);
                }
            }

            if (maxX < minX || maxY < minY)
                return;

            const marginX = Math.max(1, Math.round((maxX - minX + 1) * 0.025));
            const marginY = Math.max(1, Math.round((maxY - minY + 1) * 0.025));
            minX = Math.max(0, minX - marginX);
            minY = Math.max(0, minY - marginY);
            maxX = Math.min(pixels.width - 1, maxX + marginX);
            maxY = Math.min(pixels.height - 1, maxY + marginY);

            root.analyzedSize = Qt.size(pixels.width, pixels.height);
            root.contentRect = Qt.rect(minX, minY, maxX - minX + 1, maxY - minY + 1);
            root.analyzed = true;
        }

        onImageLoaded: requestPaint()
        onAvailableChanged: {
            if (available && isImageLoaded(root.requestedSource))
                requestPaint();
        }
        onPaint: analyzePixels()
    }

    Image {
        id: icon
        x: root.analyzed ? -root.contentCenterOffsetX * root.normalizedScale : 0
        y: root.analyzed ? -root.contentCenterOffsetY * root.normalizedScale : 0
        width: root.width
        height: root.height
        source: root.source
        sourceSize: Qt.size(128, 128)
        fillMode: Image.PreserveAspectFit
        horizontalAlignment: Image.AlignHCenter
        verticalAlignment: Image.AlignVCenter
        asynchronous: true
        mipmap: true
        scale: root.normalizedScale
        transformOrigin: Item.Center
        visible: root.ready
    }
}
