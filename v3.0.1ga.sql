-- 会员导入增加积分卡号
alter table w_member add w_card_id varchar2(40);
comment on column w_member.w_card_id
  is '积分卡号';

-- 删除中性性别
delete from m_code m where m.code_name1='中性' or m.code_name2='中性';
commit;


CREATE OR REPLACE PACKAGE BODY PK_IMPORT_MEMBER   IS
  PROCEDURE SET_IMPORT_MEMBER
  (
    PARAM_KIGYO_ID    IN  M_KIGYOU.KIGYO_ID%TYPE,
    PARAM_PC_USER_ID  IN  W_IMPORT_ERROR.PC_USER_ID%TYPE,
    PARAM_SEQ_NO    IN  W_IMPORT_ERROR.PROC_SEQ_NO%TYPE,
    OUT_ERROR      OUT  NUMBER
  )
  IS
    ERROR_ROW_COUNT  NUMBER(10,0);
        SUCCESS_ROW_COUNT  NUMBER(10,0);
        m_member_info m_member%rowtype;
        chk_number    NUMBER(10,0);
  BEGIN

      --戻り値 OUT_ERROR 設定内容
    --0 : 正常終了
    --1 : 一部エラー有。その他取込済
    --2 : 全キャンセル
    OUT_ERROR := 0;

    --入力チェック
        PK_IMPORT_CHECK.MEMBER_CHECK(PARAM_KIGYO_ID,PARAM_PC_USER_ID,PARAM_SEQ_NO);

        FOR REC IN(
        SELECT
                  KIGYO_ID,
                    W_MEMBER_ID     AS MEMBER_ID,
                    W_MEMBER_NAME     AS MEMBER_NAME,
                    W_YUUBIN_NO     AS YUUBIN_NO,
                    W_ADDRESS1       AS ADDRESS1,
                    W_ADDRESS2       AS ADDRESS2,
                    W_ADDRESS3       AS ADDRESS3,
                    W_PHONE_NO       AS PHONE_NO,
                    W_BIRTHDAY       AS BIRTHDAY,
                    W_SEX         AS SEX,
                    W_ENROLLMENT_DATE   AS ENROLLMENT_DATE,
                    W_WITHDRWAL_DATE   AS WITHDRWAL_DATE,
                    W_LANK_ID       AS LANK_ID,
                    W_POINT_VALUE     AS POINT_VALUE,
                    W_TOTAL_SALES     AS TOTAL_SALES,
                    W_LANK_LINK_KBN   AS LANK_LINK_KBN,
                    W_BIKOU       AS BIKOU,
                    W_JIGYOSYO_ID     AS JIGYOSYO_ID,
                    W_HIKADOU_FLG     AS HIKADOU_FLG,
                    w_card_id         as card_id,
                    ERROR_FLG,
          PROCEED_FLG,
          LOAD_SEQ
          FROM
              W_MEMBER
          WHERE
                  KIGYO_ID = PARAM_KIGYO_ID AND
              PROCEED_FLG = '9' AND
          ERROR_FLG = '0'
        ) LOOP
        

        -- 积分卡号是否更新,若更新,则插入积分卡表
    IF REC.card_id IS NOT NULL then
        select count(*)
          into chk_number
          from m_member
         where kigyo_id = REC.kigyo_id
           and member_id = REC.member_id;
        if chk_number > 0 then
          select *
            into m_member_info
            from m_member
           where kigyo_id = REC.kigyo_id
             and member_id = REC.member_id;
          if (m_member_info.kigyo_id is null) or (m_member_info.card_id <> REC.card_id) then
            update m_member_score_card
               set use_flag = 0
             where kigyo_id = REC.kigyo_id
               and member_id = REC.member_id;
            insert into m_member_score_card
              (kigyo_id,
               member_id,
               card_id,
               rank_id,
               pre_card_id,
               jigyosyo_id,
               point_value,
               use_flag)
            values
              (REC.kigyo_id,
               REC.member_id,
               REC.card_id,
               m_member_info.lank_id,
               m_member_info.card_id,
               REC.jigyosyo_id,
               m_member_info.point_value,
               '1');
          end if;
         else
            insert into m_member_score_card
              (kigyo_id,
               member_id,
               card_id,
               rank_id,
               pre_card_id,
               jigyosyo_id,
               point_value,
               use_flag)
            values
              (REC.kigyo_id,
               REC.member_id,
               REC.card_id,
               REC.lank_id,
               null,
               REC.jigyosyo_id,
               REC.point_value,
               '1');
        end if;   
    end if;
        
                --Member Master更新_登録
        UPDATE M_MEMBER SET
                    MEMBER_NAME   =REC.MEMBER_NAME,
                    YUUBIN_NO     =REC.YUUBIN_NO,
                    ADDRESS1     =REC.ADDRESS1,
                    ADDRESS2     =REC.ADDRESS2,
                    ADDRESS3     =REC.ADDRESS3,
                    PHONE_NO     =REC.PHONE_NO,
                    BIRTHDAY     =to_date(REC.BIRTHDAY,'yyyy/MM/dd'),
                    SEX       =REC.SEX,
                    ENROLLMENT_DATE =to_date(REC.ENROLLMENT_DATE,'yyyy/MM/dd'),
                    WITHDRWAL_DATE   =to_date(REC.WITHDRWAL_DATE,'yyyy/MM/dd'),
                    LANK_ID     =REC.LANK_ID,
                    POINT_VALUE   =REC.POINT_VALUE,
                    TOTAL_SALES   =REC.TOTAL_SALES,
                    LANK_LINK_KBN   =REC.LANK_LINK_KBN,
                    BIKOU       =REC.BIKOU,
                    JIGYOSYO_ID   =REC.JIGYOSYO_ID,
                    HIKADOU_FLG   =REC.HIKADOU_FLG,
                    KOUSHIN_DAE    =SYSDATE
        WHERE
          KIGYO_ID = REC.KIGYO_ID AND
          MEMBER_ID = REC.MEMBER_ID;

                IF SQL%ROWCOUNT=0 THEN
          INSERT INTO M_MEMBER (
                      KIGYO_ID,
                        MEMBER_ID,
                      MEMBER_NAME,
                        YUUBIN_NO,
                        ADDRESS1,
                        ADDRESS2,
                        ADDRESS3,
                        PHONE_NO,
                        BIRTHDAY,
                        SEX,
                        ENROLLMENT_DATE,
                        WITHDRWAL_DATE,
                        LANK_ID,
                        POINT_VALUE,
                        TOTAL_SALES,
                        LANK_LINK_KBN,
                        BIKOU,
                        JIGYOSYO_ID,
                        HIKADOU_FLG,
                        SAKUSEI_DATE,
                        KOUSHIN_DAE
          ) VALUES (
                      REC.KIGYO_ID,
                        REC.MEMBER_ID,
                        REC.MEMBER_NAME,
                        REC.YUUBIN_NO,
                        REC.ADDRESS1,
                        REC.ADDRESS2,
                        REC.ADDRESS3,
                        REC.PHONE_NO,
                        to_date(REC.BIRTHDAY,'yyyy/MM/dd'),
                        REC.SEX,
                        to_date(REC.ENROLLMENT_DATE,'yyyy/MM/dd'),
                        to_date(REC.WITHDRWAL_DATE,'yyyy/MM/dd'),
                        REC.LANK_ID,
                        REC.POINT_VALUE,
                        REC.TOTAL_SALES,
                        REC.LANK_LINK_KBN,
                        REC.BIKOU,
                        REC.JIGYOSYO_ID,
                        REC.HIKADOU_FLG,
                        SYSDATE,
                        SYSDATE
            );
        END IF;
    END LOOP;

    --フラグ更新
        UPDATE
        W_MEMBER
    SET
        PROCEED_FLG='1'
    WHERE
        KIGYO_ID=PARAM_KIGYO_ID AND
      PROCEED_FLG = '9' AND
      ERROR_FLG = '0';
        --success count log
        SELECT
      COUNT(DISTINCT W_MEMBER_ID) INTO SUCCESS_ROW_COUNT
    FROM
      W_MEMBER
    WHERE
        KIGYO_ID=PARAM_KIGYO_ID AND
      PROCEED_FLG = '1' AND
      ERROR_FLG = '0';
        PK_MEMBER_IMPORT_LOG.MEMBER_IMPORT_LOG(PARAM_KIGYO_ID,PARAM_PC_USER_ID,PARAM_SEQ_NO,SUCCESS_ROW_COUNT,'01');
    --エラーによる未処理のデータ件数を取得
    SELECT
      COUNT(*) INTO ERROR_ROW_COUNT
    FROM
      W_MEMBER
    WHERE
        KIGYO_ID=PARAM_KIGYO_ID AND
      PROCEED_FLG = '9' AND
      ERROR_FLG = '1';
    IF ERROR_ROW_COUNT > 0 THEN
      OUT_ERROR := 1;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      OUT_ERROR := 2;
      dbms_output.put_line(SQLERRM);
  END;
END;
/