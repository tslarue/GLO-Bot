set.seed(1)

library(tidyverse)
library(Matrix)
library(MCMCglmm)
library(moiR) 
library(dplyr)
library(lattice)
library(reshape)

# ------------ Load data ------------
setwd("/home/tlarue/safedata/ath_roots")
#setwd("/Volumes/Shared/Labs/Dinneny Lab/Private/Therese/0_TODAY/TL-38-clean")

calculated_traits <-read.csv("/home/tlarue/dinneny/Private/Therese/0_TODAY/TL-38-clean/3-analysis/calculated_traits.csv")
d <- calculated_traits

# ------------ Pick trait ------------
TRAIT <- 'depth_width'

# ------------ Subset data for modeling ------------
# pheno: TRAIT 
# acession: genotype
# line: transformed genotype
# hour: time of imaging
# experiment: replicate

d1<-d %>% dplyr::select(TRAIT, accession,line, hours, experiment)
colnames(d1)<-c("pheno","accession","line","time","replicate")


# ------------ Null model ------------
model.null<-MCMCglmm(data=d1,
                    nitt=2000,thin=100,burnin=10,
                    scale(pheno) ~ 1 )

# ------------ Run model2 (with time:accession) ------------
numberofiterations=1000000
model.2a<-MCMCglmm(data=d1,
                 nitt=numberofiterations,thin=1000,burnin=numberofiterations*0.2,
                 scale(pheno) ~ time , random=~ accession + replicate + idh(time):accession, #* equivalent
                 #scale(pheno) ~ time , random=~ replicate + us(1+time):accession, #* equivalent
                 pl=T,
                 pr=T)

model.2b<-MCMCglmm(data=d1,
                 nitt=numberofiterations,thin=1000,burnin=numberofiterations*0.2,
                 scale(pheno) ~ time , random=~ accession + replicate + idh(time):accession, #* equivalent
                 #scale(pheno) ~ time , random=~ replicate + us(1+time):accession, #* equivalent
                 pl=T,
                 pr=T)

model.2c<-MCMCglmm(data=d1,
                 nitt=numberofiterations,thin=1000,burnin=numberofiterations*0.2,
                 scale(pheno) ~ time , random=~ accession + replicate + idh(time):accession, #* equivalent
                 #scale(pheno) ~ time , random=~ replicate + us(1+time):accession, #* equivalent
                 pl=T,
                 pr=T)

# ------------ Save models ------------
dir.create(paste("mcmc_", TRAIT, sep =""))

saveRDS(model.null, paste0("mcmc_", TRAIT, "/mcmc_", TRAIT, "_modelnull.rda"))
saveRDS(model.2a, paste0("mcmc_", TRAIT, "/mcmc_", TRAIT, "_model2a.rda"))
saveRDS(model.2b, paste0("mcmc_", TRAIT, "/mcmc_", TRAIT, "_model2b.rda"))
saveRDS(model.2c, paste0("mcmc_", TRAIT, "/mcmc_", TRAIT, "_model2c.rda"))

# ------------ Select model ------------
min.model <- function(model1, model2, model3) {
  list_mod <- list(model1, model2, model3)
  x <- which.min(c(model1[[c('DIC')]], model2[[c('DIC')]], model3[[c('DIC')]]))
  print(paste("model1:", model1[[c('DIC')]], 
              "model2:", model2[[c('DIC')]],
              "model3:", model3[[c('DIC')]]))
  print(paste("model", x, "selected"))
  return(list_mod[[x]])
}

sink(paste("mcmc_", TRAIT, "/mcmc_", TRAIT, "_modelinfo.txt", sep =""))

print("------------ Model selection ------------")

model.best <- min.model(model.2a, model.2b, model.2c)

# ------------ Examine and save fit ------------
print("------------ Model summaries ------------")
print("------------ Model null ------------")
summary(model.null,random=T)
print("------------ Model 2a ------------")
summary(model.best,random=T)

# ------------ IND MODEL Heritability type 2 ------------
print("------------ Heritability type 2 ------------")
colnames(model.best$VCV) #factors included in model
up <- model.best$VCV[,"accession"] + model.best$VCV[,"time.accession"]
down <- up + model.best$VCV[,"replicate"] + model.best$VCV[,"units"]
print("MCMCglmm::posterior")
MCMCglmm::posterior.mode(up/down)
print("HDPinterval")
HPDinterval(up/down)

sink()


pdf(paste("mcmc_", TRAIT, "/mcmc_", TRAIT, "_out.pdf", sep ="")) ##save images
# ------------ Initial data ------------
plot(d1$pheno ~d1$time, main = "Initial")
xyplot(pheno ~ time | accession, data = d1, main = "Initial")

# ------------ View models ------------
xyplot(scale(pheno) + predict(model.best) ~ time | accession, data = d1, main = "Selected Model")
plot(model.best)

# ------------ Extract breeding values ------------
bv<-MCMCglmm::posterior.mode(model.best$Sol)
bvtime<-bv[grep("time.accession",names(bv))]
bvstart<-bv[grep("^accession",names(bv))] # note ^ is used to match the start of the string
interc=bv[1]
slo=bv[2]

# ------------ Get and plot breeding values ------------
d1$scaledpheno<-scale(d1$pheno)

mylist <- list()
x <- c("hr0" = 0, "hr48" = 48,
       "hr96" = 96, "hr144" = 144,
       "hr192" = 192, "hr240" = 240,
       "hr288" = 288, "hr336" = 336, "hr384" = 384)

for(i in 1:93) {
  plot(scaledpheno~time, data=d1, main = names(bvstart[i]))
  abline(a=interc,b=slo)
  i.acc1<-bvstart[i]
  s.acc1<-bvtime[i]
  abline(a=interc+i.acc1,b=slo+s.acc1,col='red')
  
  mylist[[names(bvtime[i])]] <- c((slo+s.acc1)*x + (interc+i.acc1), bvtime[i], bvstart[i])
} 

dev.off()

fitted_pheno <- data.frame(do.call("rbind", mylist))
names(fitted_pheno)[10:11] <- c("bvtime","bvstart")


fitted_pheno <- cbind(fitted_pheno, read.table(text=row.names(fitted_pheno), sep=".",
                                               header=FALSE, col.names = c("na", "na2", "accession"), stringsAsFactors=FALSE))

fitted_pheno <- merge(fitted_pheno, unique(calculated_traits[c("accession", "ecotypeid")]), by = "accession")

write.table(fitted_pheno, paste("mcmc_", TRAIT, "/mcmc_", TRAIT, "_fittedphenotypes.csv", sep =""))

# ------------ Create fam files ------------
f<-read.table("~/safedata/2029g/2029g.fam")


for(i in 2:12){ #want the 11 columns of BVs
  pheno_col <- colnames(fitted_pheno)[i]
  merged<-merge(f[,-6],fitted_pheno[c(pheno_col,'ecotypeid')],by.x='V1',by.y="ecotypeid", all.x=T)
  merged[,6][is.na(merged[,6])] <- -9
  
  system(paste('mkdir', paste0("./GWAs/", TRAIT, "_", pheno_col)))
  write.table(quote=F,row.names=F, col.names=F,
              file=paste0("./GWAs/", TRAIT, "_", pheno_col, "/2029g.fam"), 
              merged)
  
  
  system(paste("ln ~/safedata/2029g/2029g.bed", paste0("./GWAs/", TRAIT, "_", pheno_col, "/2029g.bed")))
  system(paste("ln ~/safedata/2029g/2029g.bim", paste0("./GWAs/", TRAIT, "_", pheno_col, "/2029g.bim")))
  system(paste("ln ~/safedata/2029g/2029g.cXX.txt", paste0("./GWAs/", TRAIT, "_", pheno_col, "/2029g.cXX.txt")))
  
  write.table(quote=F,row.names=F,col.names=F,
              file=paste0("./GWAs/", TRAIT, "_", pheno_col, "/rungwa.sh"),
              x=rbind(
                "#!/bin/bash",
                "#SBATCH --time=0-0:30",
                "#SBATCH --cpus-per-task=1",
                "#SBATCH --mem-per-cpu=6G",
                # "#SBATCH --partition=DPB,SHARED,PREEMPTION",
                paste0("#SBATCH --job-name=",paste0(TRAIT, "_", pheno_col)),
                paste0("#SBATCH --output=",paste0(TRAIT, "_", pheno_col),".slurm.log"),
                paste("../../gemma -bfile 2029g -k 2029g.cXX.txt  -lmm 4 -o ", paste0(TRAIT, "_", pheno_col))
                )
                )
  
  system(paste("cd", paste0("./GWAs/", TRAIT, "_", pheno_col), ";",'sbatch rungwa.sh'))

}
