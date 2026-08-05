function get_custom_axisY(values, graph) {
    if (values.length === 0)
        return [0, 0.5];

    let minValue = 100;
    let maxValue = -1;
    for (let i = 0; i < values.length; i++) {
        if (values[i] > 6.5 || values[i] < 0.01)
            continue;
        if (values[i] < minValue)
            minValue = values[i];
        if (values[i] > maxValue)
            maxValue = values[i];
    }
    let rndMin = Math.round((minValue - graph.margin) * 100) / 100;
    let rndMax = Math.round((maxValue + graph.margin) * 100) / 100;

    if (rndMax - rndMin > graph.minWindowSize)
        return [rndMin, rndMax];

    if (rndMin > graph.axisY.min && graph.axisY.min > 0 && graph.axisY.max <= 6.5) {
        if (rndMax > graph.axisY.max) {
            if (rndMin + graph.minWindowSize > 6.5)
                return [6.5 - graph.minWindowSize, 6.5];
            return [rndMin, rndMin + graph.minWindowSize];
        }
        return [graph.axisY.min, graph.axisY.max];
    }
    if (rndMax - graph.minWindowSize < 0)
        return [0, graph.minWindowSize];
    if (rndMin < graph.axisY.min)
        return [rndMax - graph.minWindowSize, rndMax];
    if (rndMin + graph.minWindowSize > 6.5)
        return [6.5 - graph.minWindowSize, 6.5];
    return [rndMin, rndMin + graph.minWindowSize];
}
