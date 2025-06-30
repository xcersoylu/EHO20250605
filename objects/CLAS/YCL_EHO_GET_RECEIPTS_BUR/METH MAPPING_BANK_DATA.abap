  METHOD mapping_bank_data.
    TYPES:
      BEGIN OF ty_detail,
        karsiiban         TYPE string,
        karsitcknvkn      TYPE string,
        valortarihi       TYPE string,
        islemtarihi       TYPE string,
        islemsaati        TYPE string,
        referansno        TYPE string,
        tutar             TYPE string,
        sonbakiye         TYPE string,
        aciklama          TYPE string,
        fonksiyonkodu     TYPE string,
        fisno             TYPE string,
        islemiyapansube   TYPE string,
        mt940trantypecode TYPE string,
      END OF ty_detail .
    TYPES:
      BEGIN OF ty_hesap,
        hesapno       TYPE string,
        subekodu      TYPE string,
        dovizkodu     TYPE string,
        iban          TYPE string,
        caribakiye    TYPE string,
        bakiye        TYPE string,
        sonbakiye     TYPE string,
        hesapturukodu TYPE string,
        detay         TYPE TABLE OF ty_detail WITH DEFAULT KEY.
    TYPES END OF ty_hesap .
    TYPES:
      BEGIN OF ty_result.
    TYPES hesaphareketleriresult TYPE TABLE OF ty_hesap WITH DEFAULT KEY.
    TYPES END OF ty_result .
    DATA ls_json_response TYPE ty_result.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    DATA lv_sequence_no TYPE int4.
    data lv_opening_balance type yeho_e_opening_balance.
    data lv_closing_balance type yeho_e_closing_balance.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    READ TABLE ls_json_response-hesaphareketleriresult INTO DATA(ls_hesap) WITH KEY iban = ms_bankpass-iban.
    lv_opening_balance = ls_hesap-bakiye.
    lv_closing_balance = ls_hesap-caribakiye.
    LOOP AT ls_hesap-detay INTO DATA(ls_detay).
      lv_sequence_no += 1.
      ls_offline_data-companycode             = ms_bankpass-companycode.
      ls_offline_data-glaccount               = ms_bankpass-glaccount.
      ls_offline_data-sequence_no             = lv_sequence_no.
      ls_offline_data-currency                = ms_bankpass-currency.
      ls_offline_data-amount                  = ls_detay-tutar.
      ls_offline_data-description             = ls_detay-aciklama.
      ls_offline_data-counter_account_no      = ls_detay-karsıtcknvkn.
      ls_offline_data-sender_iban             = ls_detay-karsiiban.
      ls_offline_data-additional_field1       = ls_detay-referansno.
      ls_offline_data-additional_field2       = ls_detay-fonksiyonkodu.
      ls_offline_data-current_balance         = ls_detay-sonbakiye.
      ls_offline_data-receipt_no              = ls_detay-fisno.
      ls_offline_data-physical_operation_date = ls_detay-islemtarihi.
      ls_offline_data-operationalglaccount    = ls_hesap-hesapno.

      CONCATENATE ls_detay-islemsaati(2)
                  ls_detay-islemsaati+3(2)
                  ls_detay-islemsaati+6(2)
      INTO ls_offline_data-time.

      ls_offline_data-valor                 = ls_detay-valortarihi.
      ls_offline_data-transaction_type            = ls_detay-mt940trantypecode.

      IF ls_offline_data-amount LT 0.
        ls_offline_data-debit_credit = 'B'.
      ELSE.
        ls_offline_data-debit_credit = 'A'.
      ENDIF.

      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
    if sy-subrc <> 0.
    lv_closing_balance = lv_opening_balance.
    endif.
    APPEND VALUE #( companycode = ms_bankpass-companycode
                    glaccount = ms_bankpass-glaccount
                    valid_from = mv_startdate
                    account_no = ms_bankpass-bankaccount
                    branch_no = ms_bankpass-branch_code
                    branch_name_description = ycl_eho_utils=>get_branch_name(
                                                iv_companycode = ms_bankpass-companycode
                                                iv_bank_code   = ms_bankpass-bank_code
                                                iv_branch_code = ms_bankpass-branch_code
                                              )
                    currency = ms_bankpass-currency
                    opening_balance =  lv_opening_balance
                    closing_balance = lv_closing_balance
                    bank_id =  ''
                    account_id = ''
                    bank_code =   ms_bankpass-bank_code
    ) TO  et_bank_balance.

  ENDMETHOD.