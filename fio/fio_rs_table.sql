CREATE TABLE "main"."<table_name>" (
    "task_id" INTEGER NOT NULL, 
    "task_name" text, 
    "client_num" integer, 
    "r_size" text, 
    "run_type" text, 
    "iodepth" text, 
    "jobs" TEXT, 
    "mode" TEXT, 
    "rwmix" TEXT, 
    "dev" TEXT, 
    "read_iops" TEXT, 
    "write_iops" TEXT, 
    "total_iops" TEXT, 
    "read_bw" TEXT, 
    "write_bw" TEXT, 
    "total_bw" TEXT, 
    "write_lat" TEXT, 
    "read_lat" TEXT, 
    "total_lat" TEXT, 
    "read_clat" TEXT, 
    "write_clat" TEXT, 
    "total_clat" TEXT, 
    "read_slat" TEXT, 
    "write_slat" TEXT, 
    "total_slat" TEXT, 
    PRIMARY KEY("task_id")
);
