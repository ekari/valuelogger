import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle
{
    id: chart
    width: parent.width
    height: parent.height
    color: "transparent"

    property var dataListModel: null
    property string column: "value"

    property int min : 0
    property int max : 1

    property date xstart : new Date()
    property date xend : new Date()

    property var plotColors: [ "white", "yellow", "green" ]

    function getMinMax(data)
    {
        var last = data.length - 1;
        var first = 0;

        var s = new Date(data[0]["timestamp"])

        if (s.getTime() < xstart.getTime())
            xstart = s

        s = new Date(data[data.length-1]["timestamp"])

        if (s.getTime() > xend.getTime())
            xend = s

        xStart.text = Qt.formatDateTime(xend, "dd.MM.yyyy hh:mm")
        xEnd.text = Qt.formatDateTime(xstart, "dd.MM.yyyy hh:mm")

        first = 0;
        last = data.length - 1;

        for (var i = first; i <= last; i++)
        {
            var l = data[i]

            if (l[column] > max)
                max = l[column];

            if (l[column] < min)
                min = l[column];
        }

        valueMax.text = max.toFixed(2)
        valueMin.text = min.toFixed(2)
        for (var midIndex=0; midIndex<4; midIndex++)
            valueMiddle.itemAt(midIndex).text = (((max+min) / 5.)*(midIndex+1)).toFixed(2)
    }

    function update()
    {

//        getMinMax(dataListModel)

        canvas.requestPaint();
    }

    Text
    {
        id: xStart
        color: Theme.primaryColor
        font.pointSize: 12
        wrapMode: Text.WordWrap
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: parent.top
        text: "unk"
    }

    Text
    {
        id: xEnd
        color: Theme.primaryColor
        font.pointSize: 12
        wrapMode: Text.WordWrap
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        horizontalAlignment: Text.AlignRight
        text: "unk"
    }

    Text
    {
        id: valueMax
        color: Theme.primaryColor
        width: 50
        font.pointSize: 12
        wrapMode: Text.WordWrap
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: xEnd.bottom
        text: "unk"
    }

    Text
    {
        id: valueMin
        color: Theme.primaryColor
        width: 50
        font.pointSize: 12
        wrapMode: Text.WordWrap
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        text: "unk"
    }

    Repeater
    {
        id: valueMiddle
        model:4

        Text
        {
            color: Theme.primaryColor
            width: 50
            font.pointSize: 12
            wrapMode: Text.WordWrap
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: (index+1) * ((parent.height/5) - 12 )
            text: "unk"
            z: 10
        }
    }

    Canvas
    {
        id: canvas
        width: parent.width
        anchors.top: valueMax.bottom
        anchors.bottom: valueMin.top
        renderTarget: Canvas.FramebufferObject
        antialiasing: true

        property int first: 0
        property int last: 0

        function drawBackground(ctx)
        {
            ctx.save();

            // clear previous plot
            ctx.clearRect(0,0,canvas.width, canvas.height);

            // fill translucent background
            // ctx.fillStyle = Qt.rgba(0,0,0,0.5);
            // ctx.fillRect(0, 0, canvas.width, canvas.height);

            // draw grid lines
            ctx.strokeStyle = Qt.rgba(1,1,1,0.3);
            ctx.beginPath();

            var cols = 6.0;
            var rows = 5.0;

            for (var i = 0; i < rows; i++)
            {
                ctx.moveTo(0, i * (canvas.height/rows));
                ctx.lineTo(canvas.width, i * (canvas.height/rows));
            }
            for (i = 0; i < cols; i++)
            {
                ctx.moveTo(i * (canvas.width/cols), 0);
                ctx.lineTo(i * (canvas.width/cols), canvas.height);
            }
            ctx.stroke();

            ctx.restore();
        }

        function drawPlot(ctx, data, color, column)
        {
            ctx.save();
            ctx.globalAlpha = 1.0;
            ctx.strokeStyle = color;
            ctx.lineWidth = 2;
            ctx.beginPath();

            for (var i = 0; i < data.length; i++)
            {
                var s = new Date(data[i]["timestamp"])
                var x = (s.getTime() - xstart)/(xend-xstart);
                var y = (data[i][column]-min)/(max-min);

                if (i == 0)
                {
                    ctx.moveTo(x * canvas.width, (1-y) * canvas.height);
                }
                else
                {
                    ctx.lineTo(x * canvas.width, (1-y) * canvas.height);
                }
            }
            ctx.stroke();
            ctx.restore();
        }

        onCanvasSizeChanged: requestPaint();

        onPaint:
        {
            console.log("onPaint")
            var ctx = canvas.getContext("2d");

            ctx.globalCompositeOperation = "source-over";
            ctx.lineWidth = 2;

            drawBackground(ctx);

            if (!dataListModel)
            {
                console.log("not ready")
                return;
            }

            for (var n=0; n<dataListModel.length; n++)
                getMinMax(dataListModel[n])

            console.log("min " + min + " max " + max)
            console.log("start " + Qt.formatDateTime(xstart, "dd.MM.yyyy hh:mm") + " end " + Qt.formatDateTime(xend, "dd.MM.yyyy hh:mm"))

            for (n=0; n<dataListModel.length; n++)
                drawPlot(ctx, dataListModel[n], plotColors[n], column);
        }
    }
}
