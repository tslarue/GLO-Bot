# Libraries ----------------------------------------------------------------
library(plyr)
library(tidyverse)
library(geometry)

# Setup and import ----------------------------------------------------------------
setwd("/home/tlarue/dinneny/Private/Therese/0_TODAY/TL-38-clean")

tip_local_tidy <- read.csv("1-working_files/tip_local_data_bind_tidy.csv", header = TRUE)
trial <- tip_local_tidy 

#filter out known problematic rhizotrons
trial <- trial %>% filter(barcode != "GWA4-R084") 
trial <- trial %>% filter(barcode != "GWA4-R092")
trial <- trial %>% filter(id != "GWA4-R091-14")

# Setup to run ----------------------------------------------------------------
computed_traits <- data.frame(id = character(),
                              convexhull = integer(),
                              xmin = integer(),
                              xmax = integer(),
                              colMeans.x = integer(),
                              colMeans.y = integer(), 
                              depth = integer(),
                              total_length = integer(),
                              weight_avg_angle = integer())

ROIs <- data.frame(id = character(),
                   x = integer(),
                   y = integer())

true_root <- data.frame()
removed_points <- data.frame()
subsetB <- data.frame()

all_barcodes <- unique(trial$barcode)
count <- 1 

# Run ----------------------------------------------------------------
dir.create("2-clean_output")
sink("2-clean_output/GWA_clean.txt")

for (i in 1:length(all_barcodes)) {
  
  name <- paste("2-clean_output/GWA_clean_", all_barcodes[i], ".pdf", sep="")
  pdf(name, width=5,height=8)
  
  print(paste("--------------------", count, "out of", length(all_barcodes), "--------------------"))
  
  subsetA <- trial %>% 
    filter(barcode == all_barcodes[i]) 
  subsetB <- data.frame()
  
  days <- sort(unique(subsetA$day))
  
  for (j in 1:length(days)) {
    
    print(paste("---------------", all_barcodes[i], "-", days[j], "---------------"))
    
    subsetC <- subsetA %>% filter(day == days[j]) # get the new points for the day
    subsetB <- rbind(subsetB, subsetC) # add them to the existing root that is "ok"
    test_hold <- data.frame()
    
    print(subsetB %>%
            ggplot(aes(x, y)) +
            geom_point(size=1) +
            xlim(0,15) +
            scale_y_reverse(limits=c(30,0)) + 
            ggtitle(paste("Rhizotron",all_barcodes[i],"start day",days[j])) )
    
    test <- subsetB %>% select(x = end_x,y = end_y)
    
    k <- 5 # keeps the while loop going
    round <- 1 # rounds of cleaning
    proximity <- 1.4 # cm away from other root 
    
    while (k > 1) {
      print (paste("day", days[j],"round:", round))
      
      d <- dist(test) # compute distances between points
      mat_d <- as.matrix(d)
      
      fit <- hclust(d, method="single") # cluster the distances 
      groups <- cutree(fit, k=2) # split tree into 2 groups 
      mat_d_sub <- mat_d[which(groups==1), which(groups==2)] # distances between the two groups
      
      print(paste("distance between clusters:", min(mat_d_sub)))
       
      if (min(mat_d_sub) > proximity) {
        test2 <- cbind(test,groups)
        
        print(test2 %>%
                ggplot(aes(x, y, color = factor(groups) )) +
                geom_point(size=1) +
                xlim(0,15) +
                scale_y_reverse(limits=c(30,0)) + 
                theme(legend.position = "none") + 
                ggtitle(paste("Round", round, "- min", min(mat_d_sub))) )

        # pick the cluster closest to the center and keep it. assign other cluster to rem_pts
        cluster <- test2 %>% 
          mutate(dist = sqrt((7.5-x)^2+(0-y)^2)) %>%
          slice(which.min(dist))%>%
          .$groups
        test <- test2 %>%
          filter(groups == cluster) %>%
          select(-groups)
        rem_pts <- test2 %>%
          filter(groups != cluster) %>%
          select(-groups)
        
        if(min(mat_d_sub) > 4) { # if the cluster is super far away, remove it and move on 
          
          print("Cluster removed - very far away")

          rem_pts$round <- round
          rem_pts2 <- inner_join(subsetB, rem_pts, by = c('end_x' = 'x', 'end_y' = 'y'))
          removed_points <- rbind(removed_points, rem_pts2)
          
        } else { # otherwise, examine the rem_pts cluster 
          
           print(paste("points in cluster:" , nrow(rem_pts)))
          
          if (nrow(rem_pts) > 4) { # if there are more than 4 points in a group 
            
            linearMod <- lm(x~y, data = rem_pts)
            sum_linearMod <- summary(linearMod)
            print(sum_linearMod$r.squared)
            
            print(rem_pts %>% ggplot(aes(x,y)) + geom_point() + ggtitle(paste("R2", sum_linearMod$r.squared)) )
            
            if (sum_linearMod$r.squared > 0.6 | #if it meets any of these parameters keep these things 
                sum_linearMod$r.squared > 0.2 & mean(rem_pts$x)<mean(test$x)+2 & mean(rem_pts$x)>mean(test$x)-2 |
                diff(range(rem_pts$x)) < 0.2) {
              
              print("Cluster kept:")
              print(paste("R-squared > 0.6", sum_linearMod$r.squared > 0.6))
              print(paste("R-squared > 0.2 & mean rem_pts w/in mean test +/-2", sum_linearMod$r.squared > 0.2 & mean(rem_pts$x)<mean(test$x)+2 & mean(rem_pts$x)>mean(test$x)-2))
              print(paste("x range of rem_pts < 0.2", diff(range(rem_pts$x)) < 0.2))

              test_hold <- rbind(test_hold,rem_pts)
              
            } else { 
              
              print("Cluster removed:")
              print(paste("R-squared > 0.6", sum_linearMod$r.squared > 0.6))
              print(paste("R-squared > 0.2 & mean rem_pts w/in mean test +/-2", sum_linearMod$r.squared > 0.2 & mean(rem_pts$x)<mean(test$x)+2 & mean(rem_pts$x)>mean(test$x)-2))
              print(paste("x range of rem_pts < 0.2", diff(range(rem_pts$x)) < 0.2))
              
              rem_pts$round <- round
              rem_pts2 <- inner_join(subsetB, rem_pts, by = c('end_x' = 'x', 'end_y' = 'y'))
              removed_points <- rbind(removed_points, rem_pts2)
              
            }

          } else { # otherwise, less than 4 points, just remove it 
            print("Cluster removed - less than 4 points")
            rem_pts$round <- round
            rem_pts2 <- inner_join(subsetB, rem_pts, by = c('end_x' = 'x', 'end_y' = 'y'))
            removed_points <- rbind(removed_points, rem_pts2)
          }
        }
      
        round <- round +1
        
      } else {
        test <- rbind(test, test_hold)
        k <- 0
        print(paste("No clusters to remove - completed day", days[j]))
      }
    }
    
    subsetB <- inner_join(subsetB, test, by = c('end_x' = 'x', 'end_y' = 'y'))
    
    print(subsetB %>%
            ggplot(aes(x, y)) +
            geom_point(size=1) +
            xlim(0,15) +
            scale_y_reverse(limits=c(30,0)) + 
            ggtitle(paste("Finished day",days[j])) )
    
    #calculate the hull/depth/etc.
    matrix <- data.frame(x = subsetB$start_x, y = subsetB$start_y)
    matrix <- rbind(matrix, data.frame(x = subsetB$end_x, y = subsetB$end_y))
    
    ordered_pts <- chull(matrix) #re-order the points
    ordered_pts <- c(ordered_pts,ordered_pts[1]) #close the shape
    
    matrix_order <- matrix[ordered_pts,]
    matrix_order$id <- as.character(paste(as.character(all_barcodes[i]), as.character(days[j]), sep = "-"))
    ROIs <- rbind(ROIs, matrix_order)
    
    value <- data.frame(id = as.character(paste(all_barcodes[i], days[j], sep = "-")),
                        convexhull = polyarea(matrix_order$x,matrix_order$y),
                        xmin = min(matrix$x),
                        xmax = max(matrix$x),
                        colMeans = t(colMeans(matrix)),
                        depth = max(subsetB$end_y),
                        total_length = sum(subsetB$length), 
                        weight_avg_angle = sum(abs(subsetB$angle-90)*subsetB$length)/sum(subsetB$length))
  
    computed_traits <- rbind(computed_traits, value)
    
    if(nrow(true_root) == 0) {
      true_root <- rbind(true_root,subsetB)
    } else {
      true_root <- rbind(true_root, anti_join(subsetB, true_root, by = NULL))
    }
  }
  
  #true_root <- rbind(true_root, subsetB)
  count <- count + 1
  
  dev.off() #stops the pdf
}

sink()

# Save the outputs ----------------------------------------------------------------
write.csv(ROIs, "1-working_files/clean_ROIs.csv")
write.csv(computed_traits, "1-working_files/clean_traits.csv")
write.csv(true_root, "1-working_files/clean_true_root.csv")
write.csv(removed_points, "1-working_files/clean_removed_points.csv")
