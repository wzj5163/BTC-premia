library(tidyverse)
library(ggplot2)
library(ggpubr)
library(zoo)
library(dplyr)

theme_set(theme_bw() +
            theme(text = element_text(size=15),
                  axis.line = element_line(colour = "black"),
                  # panel.border = element_blank(),
                  aspect.ratio = 1,
                  legend.title=element_blank()
            ))

ttm = 27

###### ######

setwd("~/同步空间/Pricing_Kernel/EPK/delta-neutral strategy/delta-neutral strategy_3_2_3_tau27_byMgroup_untilTTM/")
new_dir = "S0603_trading_result_by_continuous_m/"
dir.create(paste0(new_dir), showWarnings = FALSE)


###### Trading strategies by m ###### 
# f=1

files = tibble(weight = c("EW","QW","VW"))
trading_type_set = tibble(type = c("Long","Short"))

for (f in 1:nrow(files)){
  
  
  ####### Long strategies #######
  t=1
  trading_type = trading_type_set$type[t]
  
  longCall_by_m = read_csv(paste0("S03_trading_returns/",trading_type,"CallDH_by_M_",
                                  files$weight[f],".csv"))
  copy <- longCall_by_m %>%
    mutate(Cluster = 3)
  longCall_by_m <- rbind(longCall_by_m, copy) %>%
    mutate(Cluster = ifelse(Cluster==0,"Cluster0",
                            ifelse(Cluster==1,"Cluster1","Overall")))
  longCall_by_m = longCall_by_m %>% 
    group_by(steps_ahead,Cluster,Moneyness_t) %>% 
    summarise(num_traded = n(),
              mean_return = mean(R_t)*100,
              sharpe_ratio = mean(ER_t)/sqrt(var(ER_t))) %>% 
    ungroup() %>% 
    mutate(sharpe_ratio = sharpe_ratio*sqrt(365/steps_ahead), # annualized Sharpe ratio
           strategy = paste0(trading_type," Call DH")) 
  
  longPut_by_m = read_csv(paste0("S03_trading_returns/",trading_type,"PutDH_by_M_",
                                 files$weight[f],".csv"))
  copy <- longPut_by_m %>%
    mutate(Cluster = 3)
  longPut_by_m <- rbind(longPut_by_m, copy) %>%
    mutate(Cluster = ifelse(Cluster==0,"Cluster0",
                            ifelse(Cluster==1,"Cluster1","Overall")))
  longPut_by_m = longPut_by_m %>% 
    group_by(steps_ahead,Cluster,Moneyness_t) %>% 
    summarise(num_traded = n(),
              mean_return = mean(R_t)*100,
              sharpe_ratio = mean(ER_t)/sqrt(var(ER_t))) %>% 
    ungroup() %>% 
    mutate(sharpe_ratio = sharpe_ratio*sqrt(365/steps_ahead), # annualized Sharpe ratio
           strategy = paste0(trading_type," Put DH")) 
  
  longStraddle_by_m = read_csv(paste0("S03_trading_returns/DH_",trading_type,"Straddle_by_M_",
                                      files$weight[f],".csv"))
  copy <- longStraddle_by_m %>%
    mutate(Cluster = 3)
  longStraddle_by_m <- rbind(longStraddle_by_m, copy) %>%
    mutate(Cluster = ifelse(Cluster==0,"Cluster0",
                            ifelse(Cluster==1,"Cluster1","Overall")))
  longStraddle_by_m = longStraddle_by_m %>% 
    group_by(steps_ahead,Cluster,Moneyness_t) %>% 
    summarise(num_traded = n(),
              mean_return = mean(R_t)*100,
              sharpe_ratio = mean(ER_t)/sqrt(var(ER_t))) %>% 
    ungroup() %>% 
    mutate(sharpe_ratio = sharpe_ratio*sqrt(365/steps_ahead), # annualized Sharpe ratio
           strategy = paste0(trading_type," straddle")) 
  
  
  ## combine all strategies for plotting
  dat_by_m = bind_rows(longCall_by_m,longPut_by_m) %>% 
    bind_rows(longStraddle_by_m) %>%
    mutate(logreturn = log(Moneyness_t)) %>%
    mutate(simplereturn = exp(logreturn)-1)
  
  # Base plot
  by_m_plt_long_3 = ggplot(data = subset(dat_by_m, Cluster %in% c("Overall")), aes(x = simplereturn, y = mean_return, group = Cluster, color = Cluster)) +
    facet_wrap(~ strategy, nrow = 1) +
    scale_color_manual(values = c("Cluster0" = "blue", "Cluster1" = "red", "Overall" = "black")) +
    theme(axis.text.x = element_text(angle = 0, vjust = 0.5, hjust=1))+
    labs(title = "", x = "Simple return (K-S)/S", y = "Mean Return (%)")
  # Adding points only for Cluster0 and Cluster1
  by_m_plt_long_3 = by_m_plt_long_3 + 
    geom_point(data = subset(dat_by_m, Cluster %in% c("Cluster0", "Cluster1")), 
               alpha = 0.8, size = 1.5, shape = 16)
  # Adding smooth lines for Cluster0, Cluster1, and Overall
  # by_m_plt_long_3 = by_m_plt_long_3 + 
  #   geom_smooth(method = "loess", span = 2, se = FALSE, linewidth = 2) 
  by_m_plt_long_3 = annotate_figure(by_m_plt_long_3,
                                    top = text_grob(paste0("DH option until maturity returns, tau = ",ttm),
                                                    size = 30, face = "bold"))
  by_m_plt_long_3
  
  ggsave(filename = paste0(new_dir,trading_type,"DH_by_m_",files$weight[f],".png"), plot = by_m_plt_long_3, bg = "transparent", width = 10, height = 5, dpi = 300)
}





