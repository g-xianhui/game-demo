drop database if exists test;
create database test;
use test;

drop table if exists account;
create table `account`(
    `account_id` int unsigned not null auto_increment comment '账号ID',
    `platform_id` char(32) not null comment '平台ID',
    primary key(`account_id`),
    key(`platform_id`)
)engine=innodb default character set=utf8 collate=utf8_general_ci;

drop table if exists rolesimple;
create table `rolesimple`(
    `role_id` int unsigned not null comment '角色ID',
    `name` char(32) not null default ''  comment '玩家名字',
    `occupation` tinyint unsigned not null default 0 comment '职业',
    `level` smallint unsigned not null default 0 comment '等级',
    primary key(`role_id`)
)engine=innodb default character set=utf8 collate=utf8_general_ci;

drop table if exists item;
create table `item`(
    `guid` smallint unsigned not null default 0 comment '物品guid',
    `role_id` int unsigned not null default 0 comment '玩家id',
    `item_id` smallint unsigned not null default 0 comment '物品id',
    `count` smallint unsigned not null default 0 comment '数量',
    key(`role_id`)
)engine=innodb default character set=utf8 collate=utf8_general_ci;
