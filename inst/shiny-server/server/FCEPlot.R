# Expected Target Value Convergence
output$FCE_PER_FUN <- renderPlotly({
  req(input$FCEPlot.Min, input$FCEPlot.Max, length(DATA()) > 0)
  render_FV_PER_FUN()
})

get_data_FCE_PER_FUN <- reactive({
  req(input$FCEPlot.Min, input$FCEPlot.Max, length(DATA()) > 0)
  data <- subset(DATA(), ID %in% input$FCEPlot.Algs)
  fstart <- input$FCEPlot.Min %>% as.numeric
  fstop <- input$FCEPlot.Max %>% as.numeric
  generate_data.Single_Function(data, fstart, fstop, input$FCEPlot.semilogx,
                                'by_FV', include_geom_mean = T)
})

render_FV_PER_FUN <- reactive({
  withProgress({
    y_attrs <- c()
    if (input$FCEPlot.show.mean) y_attrs <- c(y_attrs, 'mean')
    if (input$FCEPlot.show.geom_mean) y_attrs <- c(y_attrs, 'geometric mean')
    if (input$FCEPlot.show.median) y_attrs <- c(y_attrs, 'median')
    show_legend <- T
    if (length(y_attrs) > 0) {
      p <- plot_general_data(get_data_FCE_PER_FUN(), x_attr = 'runtime', y_attr = y_attrs,
                             type = 'line', legend_attr = 'ID', show.legend = show_legend,
                             scale.ylog = isolate(input$FCEPlot.semilogy),
                             scale.xlog = input$FCEPlot.semilogx, x_title = "Function Evaluations",
                             y_title = "Best-so-far f(x)-value")
      show_legend <- F
    }
    else
      p <- NULL
    if (input$FCEPlot.show.CI) {
      p <- plot_general_data(get_data_FCE_PER_FUN(), x_attr = 'runtime', y_attr = 'mean',
                             type = 'ribbon', legend_attr = 'ID', lower_attr = 'lower',
                             upper_attr = 'upper', p = p, show.legend = show_legend)
      show_legend <- F
    }

    else if (input$FCEPlot.show.IQR) {
      IOHanalyzer.quantiles.bk <- getOption("IOHanalyzer.quantiles")
      options(IOHanalyzer.quantiles = c(0.25, 0.75))
      p <- plot_general_data(get_data_FCE_PER_FUN(), x_attr = 'runtime', y_attr = 'mean',
                                  type = 'ribbon', legend_attr = 'ID', lower_attr = '25%',
                                  upper_attr = '75%', p = p, show.legend = show_legend)
      show_legend <- F
      options(IOHanalyzer.quantiles = IOHanalyzer.quantiles.bk)
    }
    if (input$FCEPlot.show.runs) {
      fstart <- isolate(input$FCEPlot.Min %>% as.numeric)
      fstop <- isolate(input$FCEPlot.Max %>% as.numeric)
      data <- isolate(subset(DATA(), ID %in% input$FCEPlot.Algs))
      dt <- get_FV_sample(data, seq_RT(c(fstart, fstop), from = fstart, to = fstop, length.out = 50,
                                       scale = ifelse(isolate(input$FCEPlot.semilogx), 'log', 'linear')))
      nr_runs <- ncol(dt) - 4
      for (i in seq_len(nr_runs)) {
        p <- plot_general_data(dt, x_attr = 'runtime', y_attr = paste0('run.', i), type = 'line',
                               legend_attr = 'ID', p = p, show.legend = show_legend,
                               scale.ylog = input$FCEPlot.semilogy,
                               scale.xlog = input$FCEPlot.semilogx, x_title = "Function Evaluations",
                               y_title = "Best-so-far f(x)-value")
        show_legend <- F
      }
    }
    p
  },
  message = "Creating plot"
  )
})

output$FCEPlot.Download <- downloadHandler(
  filename = function() {
    eval(FIG_NAME_FV_PER_FUN)
  },
  content = function(file) {
    save_plotly(render_FV_PER_FUN(), file)
  },
  contentType = paste0('image/', input$FCEPlot.Format)
)


update_fv_per_fct_axis <- observe({
  plotlyProxy("FCE_PER_FUN", session) %>%
    plotlyProxyInvoke("relayout", list(yaxis = list(title = 'best-so-far-f(x)-value', type = ifelse(input$FCEPlot.semilogy, 'log', 'linear'))))
})


output$FCEPlot.Multi.Plot <- renderPlotly(
  render_FCEPlot_multi_plot()
)

get_data_FCE_multi_func_bulk <- reactive({
  data <- subset(DATA_RAW(), DIM == input$Overall.Dim)
  start <-  if (input$FCEPlot.Multi.Limitx) as.numeric(input$FCEPlot.Multi.Min) else NULL
  end <-  if (input$FCEPlot.Multi.Limitx) as.numeric(input$FCEPlot.Multi.Max) else NULL
  if (length(get_id(data)) < 20) { #Arbitrary limit for the time being
    rbindlist(lapply(get_funcId(data), function(fid) {
      generate_data.Single_Function(subset(data, funcId == fid), scale_log = input$FCEPlot.Multi.Logx,
                                    which = 'by_FV', start = start, stop = end)
    }))
  }
  else
    NULL
})

get_data_FCEPlot_multi <- reactive({
  req(isolate(input$FCEPlot.Multi.Algs))
  input$FCEPlot.Multi.PlotButton
  data <- subset(DATA_RAW(),
                 DIM == input$Overall.Dim)
  if (length(get_id(data)) < 20 & length(get_funcId(data)) < 30) {
    get_data_FCE_multi_func_bulk()[(ID %in% isolate(input$FCEPlot.Multi.Algs)) &
                                     (funcId %in% isolate(input$FCEPlot.Multi.Funcs)), ]
  }
  else {
    data <- subset(DATA_RAW(),
                   ID %in% isolate(input$FCEPlot.Multi.Algs),
                   funcId %in% isolate(input$FCEPlot.Multi.Funcs),
                   DIM == input$Overall.Dim)
    start <-  if (input$FCEPlot.Multi.Limitx) as.numeric(input$FCEPlot.Multi.Min) else NULL
    end <-  if (input$FCEPlot.Multi.Limitx) as.numeric(input$FCEPlot.Multi.Max) else NULL
    rbindlist(lapply(get_funcId(data), function(fid) {
      generate_data.Single_Function(subset(data, funcId == fid), scale_log = input$FCEPlot.Multi.Logx,
                                    which = 'by_FV', start = start, stop = end)
    }))
  }
})

render_FCEPlot_multi_plot <- reactive({
  withProgress({
  plot_general_data(get_data_FCEPlot_multi(), x_attr = 'runtime', y_attr = 'mean',
                    subplot_attr = 'funcId', type = 'line', scale.xlog = input$FCEPlot.Multi.Logx,
                    scale.ylog = input$FCEPlot.Multi.Logy, x_title = 'Function Evaluations',
                    y_title = 'Best-so-far f(x)', show.legend = T, subplot_shareX = T)
  },
  message = "Creating plot")
})

output$FCEPlot.Multi.Download <- downloadHandler(
  filename = function() {
    eval(FIG_NAME_FV_PER_FUN_MULTI)
  },
  content = function(file) {
    save_plotly(render_FCEPlot_multi_plot(), file)
  },
  contentType = paste0('image/', input$FCEPlot.Multi.Format)
)

