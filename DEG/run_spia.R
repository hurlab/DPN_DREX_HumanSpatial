filenames<-list.files(pattern="mySC.csv")
mysc<-lapply(filenames, function(x)read.csv(x,row.names = 1))
names(mysc)<-sub('_mySC.csv','',filenames)
myscs<-lapply(mysc, function(x)subset(x,p_val<0.01))
anno<-read.csv("../../mouse_symbol_entrezid.csv",row.names = 1)
allg<-anno$entrezgene_id
allg<-allg[allg!="."]
allg<-unlist(lapply(strsplit(allg,","),'[[',1))
#######
spai.function<-function(x,group=NULL,allg=NULL){
  tmp<-x[[group]]
  xg<-tmp$avg_log2FC
  names(xg)<-anno[rownames(tmp),"entrezgene_id"]
  xg<-xg[names(xg)!="."]
  names(xg)<-unlist(lapply(strsplit(names(xg),","),'[[',1))
  #only keep the unique gene
  xg<-xg[names(which(table(names(xg))==1))]
  resp<-spia(de=xg, all=allg, organism="mmu",beta=NULL,nB=2000,plots=FALSE, verbose=TRUE,combine="fisher")
  return(resp)
}
####
groups<-c("HFDvsSD","EXvsHFD","DREXvsHFD","DRvsHFD")
myscss<-myscs[groups]
library(SPIA)
resmysc<-lapply(names(myscss), function(x)spai.function(myscss,group=x,allg=allg))
names(resmysc)<-names(myscss)
rr<-do.call(rbind,resmysc)
rr$Group<-sub('\\..*','',rownames(rr))
rr%>%filter(pG<0.05)%>%ggplot(aes(Group,Name,size=-log10(pG),color=Status))+geom_point()+xlab("")+ylab("")+theme_light(base_size = 12)+
  xlim(c("HFDvsSD","DRvsHFD","EXvsHFD","DREXvsHFD"))+theme(axis.text.x=element_text(angle=90,vjust =0.5,hjust = 1))
dev.print(pdf,file="mysc_SPIA.pdf")
write.csv(rr,file="mysc_spia.csv")
####
filenames<-list.files(pattern="nmSC.csv")
nmsc<-lapply(filenames, function(x)read.csv(x,row.names = 1))
names(nmsc)<-sub('_nmSC.csv','',filenames)
nmscs<-lapply(nmsc, function(x)subset(x,p_val<0.01))
nmscss<-nmscs[groups]
###
resnmsc<-lapply(names(nmscss), function(x)spai.function(nmscss,group=x,allg=allg))
names(resnmsc)<-names(nmscss)
rr<-do.call(rbind,resnmsc)
rr$Group<-sub('\\..*','',rownames(rr))
rr%>%filter(pG<0.05)%>%ggplot(aes(Group,Name,size=-log10(pG),color=Status))+geom_point()+xlab("")+ylab("")+theme_light(base_size = 12)+
  xlim(c("HFDvsSD","DRvsHFD","EXvsHFD","DREXvsHFD"))+theme(axis.text.x=element_text(angle=90,vjust =0.5,hjust = 1))
dev.print(pdf,file="nmsc_SPIA.pdf")
write.csv(rr,file="nmsc_spia.csv")
####
filenames<-list.files(pattern="_Mac.csv")
mac<-lapply(filenames, function(x)read.csv(x,row.names = 1))
names(mac)<-sub('_Mac.csv','',filenames)
macs<-lapply(mac, function(x)subset(x,p_val<0.01))
macss<-macs[groups]
###
resmac<-lapply(names(macss), function(x)spai.function(macss,group=x,allg=allg))
names(resmac)<-names(macss)
rr<-do.call(rbind,resmac)
rr$Group<-sub('\\..*','',rownames(rr))
rr%>%filter(pG<0.05)%>%ggplot(aes(Group,Name,size=-log10(pG),color=Status))+geom_point()+xlab("")+ylab("")+theme_light(base_size = 12)+
  xlim(c("HFDvsSD","DRvsHFD","EXvsHFD","DREXvsHFD"))+theme(axis.text.x=element_text(angle=90,vjust =0.5,hjust = 1))
dev.print(pdf,file="mac_SPIA.pdf")
write.csv(rr,file="mac_spia.csv")
#####

####
filenames<-list.files(pattern="_Perineurial.csv")
per<-lapply(filenames, function(x)read.csv(x,row.names = 1))
names(per)<-sub('_Perineurial.csv','',filenames)
pers<-lapply(per, function(x)subset(x,p_val<0.01))
perss<-pers[groups]
###
resper<-lapply(names(perss), function(x)spai.function(perss,group=x,allg=allg))
names(resper)<-names(perss)
rr<-do.call(rbind,resper)
rr$Group<-sub('\\..*','',rownames(rr))
rr%>%filter(pG<0.05)%>%ggplot(aes(Group,Name,size=-log10(pG),color=Status))+geom_point()+xlab("")+ylab("")+theme_light(base_size = 12)+
  xlim(c("HFDvsSD","DRvsHFD","EXvsHFD","DREXvsHFD"))+theme(axis.text.x=element_text(angle=90,vjust =0.5,hjust = 1))
dev.print(pdf,file="Perineurial_SPIA.pdf")
write.csv(rr,file="Perineurial_spia.csv")
#####

