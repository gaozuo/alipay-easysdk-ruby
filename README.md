# Alipay EasySDK Ruby

支付宝开放平台Alipay EasySDK的Ruby版本实现，提供完整的支付宝支付功能支持。

## 🚀 特性

- ✅ **完整的支付功能** - 支持当面付、手机网站支付、APP支付、页面支付、花呗分期
- ✅ **简化API调用** - 提供链式调用支持，代码简洁优雅
- ✅ **双重签名模式** - 支持证书模式和公钥模式
- ✅ **异步通知验签** - 内置验签功能，安全可靠
- ✅ **AES加密解密** - 支持敏感数据加密传输
- ✅ **标准Gem包** - 遵循Ruby Gem最佳实践
- ✅ **完整测试覆盖** - 提供全面的单元测试

## 📦 安装

将以下代码添加到你的Gemfile中：

```ruby
gem 'alipay-easysdk-ruby'
```

然后执行：

```bash
$ bundle install
```

或者直接安装：

```bash
$ gem install alipay-easysdk-ruby
```

## 🔧 使用

### 1. 基本配置

```ruby
require 'alipay/easysdk'

# 全局配置（只需设置一次）
Alipay::EasySDK.configure(
  protocol: 'https',
  gateway_host: 'openapi.alipay.com',  # 正式环境
  # gateway_host: 'openapi-sandbox.dl.alipaydev.com',  # 沙盒环境
  app_id: 'your-app-id',
  merchant_private_key: 'your-private-key',
  alipay_public_key: 'your-alipay-public-key'
  # encrypt_key: 'your-aes-key'  # AES密钥（可选）
)
```

### 2. 手机网站支付

```ruby
# 创建手机网站支付订单
response = Alipay::EasySDK.wap.pay(
  "商品名称",                   # subject
  "20231001001",              # out_trade_no
  "99.00",                     # total_amount
  "https://quit.example.com",  # quit_url
  "https://return.example.com" # return_url
)

if response.success?
  puts "支付表单HTML: #{response.form}"
  # 可以直接输出response.form到网页中
else
  puts "调用失败: #{response.error_message}"
end
```

### 3. 当面付

```ruby
# 创建二维码支付
response = Alipay::EasySDK.facetoface.pre_create(
  "Apple iPhone11 128G",
  "2234567890",
  "5799.00"
)

if response.success?
  puts "二维码内容: #{response.qr_code}"
end
```

### 4. 查询订单

```ruby
# 查询订单状态
response = Alipay::EasySDK.common.query("20231001001")

if response.success?
  puts "订单状态: #{response.trade_status}"
  puts "支付金额: #{response.total_amount}"
end
```

### 5. 退款

```ruby
# 发起退款
response = Alipay::EasySDK.common.refund(
  "20231001001",    # out_trade_no
  "10.00",         # refund_amount
  "商品质量问题"     # refund_reason
)

if response.success?
  puts "退款成功，退款金额: #{response.refund_fee}"
end
```

### 6. 链式调用

```ruby
# ISV代商户调用，支持链式调用
response = Alipay::EasySDK.facetoface
  .agent("app_auth_token")
  .async_notify("https://your-callback-url.com")
  .optional("timeout_express", "30m")
  .optional("goods_detail", [
    {
      "goods_id" => "1001",
      "goods_name" => "iPhone 15",
      "quantity" => 1,
      "price" => "7999.00"
    }
  ])
  .pre_create("Apple iPhone15", "20231001006", "7999.00")
```

### 7. 异步通知验签

```ruby
# 在异步通知回调中验签
def alipay_notify_callback(params)
  if Alipay::EasySDK.common.verify_notify(params)
    # 验签成功，处理业务逻辑
    puts "验签成功，订单号: #{params['out_trade_no']}"
    # 处理订单更新等业务逻辑
    render text: "success"
  else
    # 验签失败
    puts "验签失败"
    render text: "fail"
  end
end
```

## 📋 API支持

### 通用支付 (Payment::Common)
- ✅ `query()` - 查询订单
- ✅ `refund()` - 申请退款
- ✅ `close()` - 关闭订单
- ✅ `cancel()` - 撤销订单
- ✅ `query_refund()` - 查询退款
- ✅ `download_bill()` - 下载对账单
- ✅ `verify_notify()` - 异步通知验签

### 当面付 (Payment::FaceToFace)
- ✅ `pay()` - 收银员扫码收款
- ✅ `pre_create()` - 生成支付二维码

### 手机网站支付 (Payment::Wap)
- ✅ `pay()` - 创建手机网站支付

### 电脑网站支付 (Payment::Page)
- ✅ `pay()` - 创建电脑网站支付

### APP支付 (Payment::App)
- ✅ `pay()` - 创建APP支付

### 花呗分期 (Payment::Huabei)
- ✅ `create()` - 花呗分期支付
- ✅ `huabei_config()` - 花呗分期配置

## 🧪 运行测试

```bash
$ bundle exec rspec
```

## 📝 示例

查看 `examples/` 目录中的完整示例代码。

```bash
$ ruby examples/demo.rb
```

## 🔗 相关链接

- [支付宝开放平台](https://open.alipay.com)
- [Alipay EasySDK文档](https://github.com/alipay/alipay-easysdk)
- [API文档](https://opendocs.alipay.com/open)

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本项目
2. 创建你的特性分支 (`git checkout -b my-new-feature`)
3. 提交你的更改 (`git commit -am 'Add some feature'`)
4. 推送到分支 (`git push origin my-new-feature`)
5. 创建一个 Pull Request