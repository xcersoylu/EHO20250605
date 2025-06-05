  METHOD mapping_bank_data.
    TYPES:
      BEGIN OF mty_hesap.
    "return parameters from bank
    TYPES businesskey                TYPE string.
    TYPES trandate                   TYPE string.
    TYPES amount                     TYPE string.
    TYPES comment                    TYPE string.
    TYPES channelid                  TYPE string.
    TYPES fec                        TYPE string.
    TYPES fecname                    TYPE string.
    TYPES tranbranchid               TYPE string.
    TYPES tranbranchname             TYPE string.
    TYPES systemdate                 TYPE string.
    TYPES sendertaxnumber            TYPE string.
    TYPES sendername                 TYPE string.
    TYPES senderaccountnumber        TYPE string.
    TYPES senderphonenumber          TYPE string.
    TYPES senderbankcode             TYPE string.
    TYPES senderbranchcode           TYPE string.
    TYPES transactiontypedescription TYPE string.
    TYPES transactiontype            TYPE string.
    TYPES receivertaxnumber          TYPE string.
    TYPES receivername               TYPE string.
    TYPES receiveraccountnumber      TYPE string.
    TYPES receiverphonenumber        TYPE string.
    TYPES receiverbankcode           TYPE string.
    TYPES receiverbranchcode         TYPE string.
    TYPES balance                    TYPE string.
    TYPES balance2                   TYPE string.
    TYPES END OF mty_hesap .
    TYPES:
      BEGIN OF mty_result.
    TYPES hesaphareketleriresult TYPE TABLE OF mty_hesap WITH DEFAULT KEY.
    TYPES END OF mty_result .
    DATA ls_json_response TYPE mty_result.
    DATA lv_sequence_no TYPE int4.
    DATA ls_offline_data TYPE yeho_t_offlinedt.
    /ui2/cl_json=>deserialize( EXPORTING json = iv_json CHANGING data = ls_json_response ).

    LOOP AT ls_json_response-hesaphareketleriresult INTO DATA(ls_detay).
      lv_sequence_no += 1.
      ls_offline_data-companycode =  ms_bankpass-companycode.
      ls_offline_data-glaccount   =  ms_bankpass-glaccount.
      ls_offline_data-sequence_no =  lv_sequence_no.

      ls_offline_data-description = ls_detay-comment.
      ls_offline_data-sender_bank = ls_detay-senderbankcode.
      ls_offline_data-sender_branch  = ls_detay-senderbranchcode.

*      CALL FUNCTION 'CLOI_PUT_SIGN_IN_FRONT'
*        CHANGING
*          value = ls_detay-amount.
      ls_offline_data-amount    = ls_detay-amount.
      IF ls_offline_data-amount > 0.
        ls_offline_data-payee_vkn = ls_detay-sendertaxnumber.
        ls_offline_data-debit_credit = 'A'.
        ls_offline_data-sender_iban = ls_detay-senderaccountnumber.
      ELSEIF ls_offline_data-amount < 0.
        ls_offline_data-debtor_vkn = ls_detay-sendertaxnumber.
        ls_offline_data-debit_credit = 'B'.
        ls_offline_data-sender_iban      = ls_detay-senderaccountnumber.
      ENDIF.

      ls_offline_data-current_balance          = ls_detay-balance.
      ls_offline_data-receipt_no            = ls_detay-businesskey.
      CONCATENATE ls_detay-trandate(4) ls_detay-trandate+5(2) ls_detay-trandate+8(2)
             INTO ls_offline_data-physical_operation_date.
      CONCATENATE ls_detay-systemdate(4) ls_detay-systemdate+5(2) ls_detay-systemdate+8(2)
             INTO ls_offline_data-accounting_date.
      CONCATENATE ls_detay-systemdate+11(2) ls_detay-systemdate+14(2) ls_detay-systemdate+17(2)
             INTO ls_offline_data-time.
      ls_offline_data-transaction_type            = ls_detay-transactiontype.
      ls_offline_data-additional_field1                = ls_detay-transactiontypedescription.
      APPEND ls_offline_data TO et_bank_data.
      CLEAR ls_offline_data.
    ENDLOOP.
" #TODO açılış kapanış bakiyesi gui de yok danışmana sor!
  ENDMETHOD.