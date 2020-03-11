require 'nokogiri'
require 'rest-client'
require 'csv'

class InfoJobs
    
  attr_reader :cidade, :estado
  
  def initialize(cidade, estado)
    @cidade = cidade.chomp.downcase.tr(' ', '-')
    @estado = estado.chomp.downcase.tr(' ', '-')
  end
  
  def run
    total_paginas
    scrapping
  ensure
    writing
  end

  private
  
  def parsing(url)
    html = RestClient.get(url)
    Nokogiri::HTML(html)
  rescue StandardError => e
    puts "Erro em #{url}"
    puts "Exeception Class:#{e.class.name}"
    puts "Exeception Message:#{e.message}"
  end
  

  def url_base
    @url_base ||= "https://www.infojobs.com.br/vagas-de-emprego-#{cidade}-em-#{estado}.aspx"
  end

  
  def total_paginas
    parsed_html = parsing(url_base)
    vagas_total = parsed_html.css('.js_xiticounter').text.delete('.')
    vagas_por_pagina = parsed_html.css('.element-vaga').count
    @ultima_pagina = (vagas_total.to_f / vagas_por_pagina).round
  end
  
  def scrapping
    @lista = Array.new
    pagina = 1
    until pagina > @ultima_pagina
      vagas = parsing("#{url_base}?Page=#{pagina}").css('.element-vaga')
      vagas.each { |vaga| @lista.push(extracao(vaga)) }
      puts "Página #{pagina} salvada com sucesso."
      pagina+=1
    end
  end
  
  def extracao(vaga)
    empresa = vaga.css('div.vaga-company > a').text.strip()
    empresa = empresa.empty? ? "Empresa Confidencial" : empresa
    {
      titulo: vaga.css('div.vaga > a > h2').text.strip(),
      empresa: empresa,
      cidade: vaga.css('p.location2 > span > span > span').text,
      area: vaga.css('p.area > span').text
    }
  end
  
  def writing
    return unless @lista && @lista.any?
    file = "lista_empregos_#{Time.now.to_i}.csv"
    CSV.open(file, 'wb', headers: @lista.first.keys) do |csv|
      csv << ['Titulo', 'Empresa', 'Cidade', 'Area']
      @lista.each do |hash|
        csv << hash
      end
    end
  end
  
end

puts '[ Digite a Cidade ] '
cidade = gets
puts '[ Digite a Unidade Federal ]'
estado = gets
puts 'Processando...'
test = InfoJobs.new(cidade, estado)
test.run
