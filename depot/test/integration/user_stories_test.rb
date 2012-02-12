# coding: utf-8

require 'test_helper'

class UserStoriesTest < ActionDispatch::IntegrationTest
   fixtures :products

   test "buying a product" do
      ## 準備。予めあるデータは全て削除
      LineItem.delete_all
      Order.delete_all
      ## よく使うデータは取っておく
      ruby_book = products(:ruby)

      ## トップページにアクセス
      get "/"
      assert_response :success
      assert_template "index"

      ## 商品をカートに入れる
      xml_http_request :post, '/line_items', product_id: ruby_book.id
      assert_response :success

      ## カートの中身の確認
      cart = Cart.find(session[:cart_id])
      assert_equal 1, cart.line_items.size
      assert_equal ruby_book, cart.line_items[0].product

      ## チェックアウトボタンをクリック
      get "/orders/new"
      assert_response :success
      assert_template "new"

      ## データを入力して送信
      post_via_redirect "/orders",
         order: { name: "Dave Thomas",
            address: "123 The Street",
            email: "dave@example.com",
            pay_type: "現金" }
      ## 結果の確認
      assert_response :success
      assert_template "index"
      cart = Cart.find(session[:cart_id])
      assert_equal 0, cart.line_items.size

      ## テーブルに登録されている内容の確認
      orders = Order.all
      assert_equal 1, orders.size
      order = orders[0]

      assert_equal "Dave Thomas", order.name
      assert_equal "123 The Street", order.address
      assert_equal "dave@example.com", order.email
      assert_equal "現金", order.pay_type

      assert_equal 1, order.line_items.size
      line_item = order.line_items[0]
      assert_equal ruby_book, line_item.product

      mail = ActionMailer::Base.deliveries.last
      assert_equal ["dave@example.com"], mail.to
      assert_equal 'Sam Ruby <depot@example.com>', mail[:from].value
      assert_equal "Pragmatic Store Order Confirmation", mail.subject
   end

end
