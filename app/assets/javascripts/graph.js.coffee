INESC = {}
INESC.Graphs = {}

INESC.Graphs.PaymentsPerMonth = do ->
  create = (svgElement, orgao, ano) ->
    fetchData(orgao, ano).then(buildGraph(svgElement))

  fetchData = (orgao, ano) ->
    openspendingUrl = "http://openspending.org/api/2/aggregate"
    autorizadoParameters =
      dataset: "inesc"
      cut: "time.year:#{ano}|orgao.label:#{orgao}"
      drilldown: "orgao|time.month"
      order: "time.month:asc"

    pagoParameters =
      measure: "pago"

    $.when(
      $.getJSON(openspendingUrl, autorizadoParameters),
      $.getJSON(openspendingUrl, $.extend(autorizadoParameters, pagoParameters))
    )

  buildGraph = (svgElement) -> (autorizado, pago) ->
     nv.addGraph () ->
         data = processData(autorizado, pago)
         chart = nv.models.multiChart()
               .x((d,i) -> parseInt(d.x))
               .color(d3.scale.category20c().range())
  
         chart.xAxis.showMaxMin(true).tickFormat((d) ->
           index = d - 1
           dx = data[0].values[index] && data[0].values[index].x
           d3.time.format('%b')(new Date(dx))
         )
     
         chart.yAxis1.showMaxMin(true)
             .tickFormat(d3.format(',s.2'))
     
         d3.select(svgElement)
             .datum(data)
           .transition().duration(500).call(chart)
     
         nv.utils.windowResize(chart.update)
     
         chart

  processData = (autorizado, pago) ->
    accumulateAmounts = (values, element) ->
      length = values.length
      amount = if length > 0 then values[length-1].y else 0
      amount += element.amount || element.pago || 0
      values.push {
        x: element.time.month,
        y: amount
      }
      values

    [
      {
        key: "Pagamentos",
        yAxis: 1,
        type: "bar",
        values: pago[0].drilldown.map (element) -> { x: element.time.month, y: element.pago }
      },
      {
        key: "Pagamentos Acumulados",
        yAxis: 1,
        type: "line",
        values: pago[0].drilldown.reduce(accumulateAmounts, [])
      },
      {
        key: "Autorizado",
        yAxis: 1,
        type: "area",
        values: autorizado[0].drilldown.reduce(accumulateAmounts, [])
      },
    ]

  api =
    create: create

INESC.Graphs.parseUrl = ->
  url = window.location.pathname.substr(1)
  [orgao, ano] = url.split("/")
  [orgao.replace(/-/g, " ").trim().toUpperCase(),
   parseInt(ano)]

$(document).ready ->
  [orgao, ano] = INESC.Graphs.parseUrl()
  INESC.Graphs.PaymentsPerMonth.create(".graph svg", orgao, ano)

