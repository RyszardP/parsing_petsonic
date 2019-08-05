require 'curb'
require 'nokogiri'
require 'csv'

puts 'The program is running'
puts 'Enter the URL from petsonic.com:'
main_page = gets.chomp()
begin
  puts 'Opening page'
  main_html = Curl.get(main_page).body_str
rescue
  puts 'Incorrect url'
end

puts 'Enter file name: '
csv_file = gets.chomp()
CSV.open(csv_file, "w") do |csv|
  csv << ["Name ", " Price ", " Image "]
end

puts 'Loading page'
html = Nokogiri::HTML(main_html)
while TRUE
  puts 'Searching products URL on page'
  link = html.xpath("//a[@class='product_img_link product-list-category-img']")
  links_list = []
  link.each do |tag|
    products_link = tag[:href]
    links_list << products_link
  end
  puts 'List of links compiled'
  puts 'Start searching products from page'
  Curl::Multi.get(links_list, :follow_location => true) do |easy|
    doct = easy.body_str
    products = Nokogiri::HTML(doct)
    product_name = products.xpath("//span[@class='navigation_page']").text.strip
    image = products.xpath("//img[@id='bigpic']").map { |pic| pic[:src] }.to_s
    price_tag = products.xpath("//label[contains(@class,'label_comb_price')]")
    price_tag.each do |w|
      temp_n= w.search('span.radio_label').text.strip
      price = w.search('span.price_comb').text.strip
      name = product_name + " - " + temp_n
      data = [
          name,
          price,
          image[2..-3]
      ]
      CSV.open(csv_file, "a") do |csv|
        csv << data
      end
      puts 'Data is written to csv file'
    end
  end
  pagination_link = html.xpath("//li[@class='pagination_next']/a").map { |url| url[:href] }
  page_s = pagination_link .to_s
  first_page_index = page_s.rindex('=').to_i + 1
  next_page = page_s[first_page_index..-2].to_i
  if next_page == 0
    puts 'Finish'
    break
  end
  url = "#{main_page}?p=#{next_page}"
  main_html = Curl.get(url).body_str
  html = Nokogiri::HTML(main_html)
end