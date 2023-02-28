rm(list=ls())
# setwd("electricity_use/")

# Set locale to get mont abbreviations into english
Sys.setlocale('LC_ALL','English')


# Packages - readxl contains excel reading function
library(data.table)
library(readxl)
library(dplyr)
library(ggplot2)


# Load data
el <- data.table(read_xlsx('data/2001360832_DAD735999100005251882_20210605-20221221A.xlsx'))[10:.N]
tmp1 <- fread('data/smhi-opendata_1_82230_20221221_121146.csv')
tmp2 <- fread('data/smhi-opendata_1_82230_20221221_121145.csv')


# Set dataset variable names
setnames(el, c('date', 'kwh'))
setnames(tmp1, c('date', 'time', 'celsius', 'quality'))
setnames(tmp2, c('date', 'time', 'celsius', 'quality'))


# Convert types in el data
el[, date:=as.Date(date)]
el[, kwh:=as.numeric(kwh)]


# Remove incomplete observations from el
el <- el[!is.na(kwh)]


# Append tmp data and remove duplicated dates
tmp <- data.table(rbind(tmp1[date < tmp2[, min(date)]], tmp2))


# Reduce to focal dates (period covered by el)
tmp <- tmp[date>=el[, min(date)] & date<=el[, max(date)]]


# Get daily temperature averages
tmp_means <- tmp[, .('celsius'=mean(celsius)), by=date]


# Merge (removing dates where data for temperature is not present)
joint <- tmp_means[el, on='date'][!is.na(celsius)]


# Recreate Vattenfall barplot
el_my <- joint[date>=as.Date('2021-07-01') & date<=as.Date('2022-12-31'), 
               .('kwh'=sum(kwh)), 
                by=.('year'=format(as.Date(date), '%Y'), 
                     'month'=format(as.Date(date), '%b'))][
               data.table(year=rep(c('2021', '2022'), each=12), month=month.abb), on=c('year', 'month')]
el_my[is.na(kwh), kwh:=0]

plot_vattenfall <- 
  ggplot(el_my, aes(y=kwh, x=month, fill=year)) +
    geom_col(position='dodge') +
    scale_x_discrete('', limits = month.abb) +
    scale_y_continuous('Electricity Consumption (kwh)', expand=c(0,0)) 


# Plot temperature and electricity usage through the year
plot_annual <- 
  ggplot(joint[, melt(.SD, id.vars='date')], 
         aes(x=as.Date(format(date,'2022-%m-%d')), y=value, color=variable)) +
    geom_point(alpha=0.6) +
    geom_smooth(se=FALSE) +
    scale_y_continuous('', limit=c(-10,100), expand=c(0,0)) +
    scale_x_date('', date_labels = '%b 1st')

# Plot temperature explaining usage
plot_kwh_c <- 
  ggplot(joint, aes(x=celsius, y=kwh)) +
    geom_point(alpha=0.6) +
    geom_smooth(se=FALSE) +
    labs(x='Average Temperature (C)', y='Electricity Used (kWh)') +
    scale_x_continuous(expand=c(0,0)) +
    scale_y_continuous(expand=c(0,0)) 



# Plot temperature explaining usage, restricted to cold weather and by year
joint[as.numeric(format(date, "%m")) %in% 1:3, season:=paste0("W", as.numeric(format(date, "%y"))-1)]
joint[as.numeric(format(date, "%m")) %in% 10:12, season:=paste0("W", format(date, "%y"))]

plot_kwh_c_cold <- 
  ggplot(joint[celsius<=15 & !is.na(season)], aes(x=celsius, y=kwh, 
                                 color=season)) +
    geom_point(alpha=0.6) +
    geom_smooth(method='lm', se=FALSE, fullrange=TRUE) +
    labs(x='Average Temperature (C)', y='Electricity Used (kWh)') +
    scale_x_continuous(expand=c(0,0)) +
    scale_y_continuous(expand=c(0,0))
  








# # Custom theme
# my_theme <- function(){
#   theme_minimal() %+replace%
#     theme(
#       # Leave only major gridlines and very light grey
#       panel.grid.major=element_line(color='#00000012'),
#       panel.grid.minor=element_blank(),
#       # Add in axes on x and y
#       axis.line.x=element_line(color='#000000'),
#       axis.line.y=element_line(color='#000000'),
#       axis.ticks=element_blank(),
#       # Position legend inside plot
#       legend.position=c('bottom'),
#       legend.justification='right',
#       legend.margin=margin(5,20,5,10),
#       legend.box.margin=margin(5,0,10,10),
#       legend.title=element_blank(),
#       legend.background=element_rect(fill='#00000006', color='#00000012')
#     )
# }
# plot_annual + 
#   my_theme() + 
#   scale_color_discrete('Variable:', labels=c('Temperature (C)', 'Electricity Use (kWh)'))
# 
# 
# plot_kwh_c + 
#   my_theme()
# 
# plot_kwh_c_cold + 
#   my_theme()

