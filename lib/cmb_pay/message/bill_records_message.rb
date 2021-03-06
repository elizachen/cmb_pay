require 'rexml/streamlistener'

module CmbPay
  class BillRecordsMessage
    attr_reader :raw_http_response, :code, :error_message,
                :query_loop_flag, :query_loop_pos, :bill_records
    def initialize(http_response)
      @raw_http_response = http_response
      return unless http_response.code == 200
      @bill_records = []

      REXML::Document.parse_stream(http_response.body, self)
    end

    def tag_start(name, _attributes)
      case name
      when 'Head'      then @in_head = true
      when 'Body'      then @in_body = true
      when 'BllRecord' then @current_bill_record = {}
      else
        @current_element_name = name
      end
    end

    def tag_end(name)
      case name
      when 'Head'      then @in_head = false
      when 'Body'      then @in_body = false
      when 'BllRecord' then @bill_records << @current_bill_record
      end
    end

    def text(text)
      if @in_head
        case @current_element_name
        when 'Code'   then @code = text
        when 'ErrMsg' then @error_message = text
        end
      elsif @in_body
        case @current_element_name
        # 续传标记(采用多次通讯方式续传时使用) 默认值为’N’，表示没有后续数据包，’Y’表示仍有后续的通讯包
        when 'QryLopFlg'    then @query_loop_flag = text
        # 续传包请求数据
        when 'QryLopBlk'    then @query_loop_pos = text
        # 商户定单号
        when 'BillNo'       then @current_bill_record[:bill_no] = text
        # 商户日期
        when 'MchDate'      then @current_bill_record[:merchant_date] = text
        # 结算日期
        when 'StlDate'      then @current_bill_record[:settled_date] = text
        # 订单状态
        when 'BillState'    then @current_bill_record[:bill_state] = text
        # 订单金额
        when 'BillAmount'   then @current_bill_record[:bill_amount] = text
        # 手续费
        when 'FeeAmount'    then @current_bill_record[:fee_amount] = text
        # 卡类型
        when 'CardType'     then @current_bill_record[:card_type] = text
        # 交易流水号
        when 'BillRfn'      then @current_bill_record[:bill_ref_no] = text
        # 实扣金额
        when 'StlAmount'    then @current_bill_record[:settled_amount] = text
        # 优惠金额
        when 'DecPayAmount' then @current_bill_record[:discount_pay_amount] = text
        # 订单类型：A表示二维码支付订单，B表示普通订单
        when 'BillType'     then @current_bill_record[:bill_type] = text
        # 如果订单类型为A，下述字段才存在
        when 'Addressee'    then @current_bill_record[:addressee] = text # 收货人姓名
        when 'Country'      then @current_bill_record[:country] = text   # 国家
        when 'Province'     then @current_bill_record[:province] = text  # 省份
        when 'City'         then @current_bill_record[:city] = text      # 城市
        when 'Address'      then @current_bill_record[:address] = text   # 街道地址
        when 'Mobile'       then @current_bill_record[:mobile] = text    # 手机号
        when 'Telephone'    then @current_bill_record[:telephone] = text # 固定电话
        when 'ZipCode'      then @current_bill_record[:zipcode] = text   # 邮编
        when 'GoodsURL'     then @current_bill_record[:goodsurl] = text  # 商品详情链接
        end
      end
    end

    def succeed?
      code.nil? && error_message.nil?
    end
  end
end
