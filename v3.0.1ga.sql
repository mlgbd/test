-- 会员导入增加积分卡号
alter table w_member add w_card_id varchar2(40);
comment on column w_member.w_card_id
  is '积分卡号';

-- 删除中性性别
delete from m_code m where m.code_name1='中性' or m.code_name2='中性';
commit;


