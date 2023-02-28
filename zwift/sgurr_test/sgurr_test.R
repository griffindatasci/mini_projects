library(data.table)
# setwd("zwift/sgurr_test/")

# Run this if the data is not available as a .csv file =========================
if(FALSE){
  # Read in data from fit file and output as a .csv
  install.packages("remotes")
  remotes::install_github("grimbough/FITfileR")
  library(data.table)
  library(FITfileR)
  fwrite(records(readFitFile("data/Zwift_City_and_the_Sgurr_in_Scotland.fit")), "data/ride_data.csv")
}

ride <- fread("data/ride_data.csv")
bikes <- fread("data/bikes.csv")
segments <- fread("data/segments.csv")


# DATA PREP ====================================================================

# Add on which bike was used (bikes.csv is a table showing distances as each piece of equipment was changed)
# ride[timestamp-lag(timestamp)>1, c(.SD, .(timestamp-lag(timestamp)))] # Use to modify bikes.csv for more precision

for(i in 1:nrow(bikes)){
  ride[distance >= bikes[i, start], bike:=..bikes[i, bike]]
}




# Lap distance, taken as last distance below 28m from first lap to last lap, divided by 9 laps
lap_dist <- (54172.13-988.70)/9


# Add lap count
lead_in <- 950
ride[, lap:=(distance-..lead_in)%/%..lap_dist+1]

# - Add lap accumulated distance, time and average power
ride[, lap_distance:=distance-min(distance), by=lap]
ride[, lap_time:=as.numeric(timestamp-min(timestamp)), by=lap]
ride[, lap_power:=mean(power), by=lap]



# Add on which segment of the route
for(i in 1:nrow(segments)){
  ride[lap_distance >= segments[i, start], segment:=..segments[i, segment]]
}





# SUMMARY ======================================================================
# - Reduce to focal laps (no bike changes)
ride <- ride[lap%in%c(1,3,7,9)]


# - Lap time for each bike/power
ride[, .("Time"=sprintf("%02.f:%02.f", max(lap_time)%/%60, max(lap_time)%%60)), 
     by=.("Bike"=bike, "W/kg"=lap_power/75)]


# - Time for each side of the Sgurr
ride[, .("seconds"=as.numeric(difftime(max(timestamp), min(timestamp), units = "s"))), 
     by=.(bike, lap_power, segment)][, 
                                 .("Time"=sprintf("%02.f:%02.f", sum(seconds)%/%60, sum(seconds)%%60)), 
                                 by=.("Bike"=bike, "W/kg"=lap_power/75, 
                                      "Side"=ifelse(grepl("north", segment), "North", "South"))][
                                        order(`W/kg`, Side, Bike)]











# DEVELOPMENT ==================================================================
# Plot time ~ distance by bike
par(mar=c(4,4,1,1))
# - base
ride[lap==1, 
     plot(lap_time~lap_distance, 
          typ="n", 
          xlab="Distance (km)", ylab="Time (minutes)", 
          axes=FALSE, xaxs="i", yaxs="i")]

# - shade the north/gravel section
polygon(x=c(0,0,1645,1645,0), 
        y=c(-10000, 10000, 10000, -10000, -10000), 
        border=NA, col="#f7f0e9")

polygon(x=c(3901,3901,lap_dist, lap_dist, 3901), 
        y=c(-10000, 10000, 10000, -10000, -10000), 
        border=NA, 
        col="#f7f0e9")


text(c("North", "South", "North"), x=c(822.5, 2773, 4906), y=rep(800, 3), col="black", cex=0.8)

# - add lines showing time ~ distance
ride[lap==1, points(lap_time~lap_distance, typ="l", col="#38486b")]
ride[lap==3, points(lap_time~lap_distance, typ="l", col="#ff0099")]
ride[lap==7, points(lap_time~lap_distance, typ="l", col="#38486b", lty=2)]
ride[lap==9, points(lap_time~lap_distance, typ="l", col="#ff0099", lty=2)]

# - add axes
axis(1, at=seq(0, 6000, by=1000), labels=seq(0, 6))
axis(2, at=seq(0, 1200, by=240), labels=seq(0, 20, by=4), las=1)







