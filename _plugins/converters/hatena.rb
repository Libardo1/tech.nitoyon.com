# Convert '*.htn' to HTML with Hatena Style
#
# hparser(at https://github.com/nitoyon/hparser/tree/nitoyon) required

module Jekyll

  class HatenaConverter < Converter
    safe true

    priority :low

    def matches(ext)
      ext =~ /htn/i
    end

    def output_ext(ext)
      ".html"
    end

    def convert(content)
      require 'hparser'

      ### HTML �ϊ��̐ݒ� ###
      # ** �� H4 �ɂȂ�悤�ɂ���
      HParser::Block::Head::head_level = 3

      # _config.yml �� pygments �� true �ɂ��Ă���Ƃ��́A�X�[�p�[ pre �L�@��
      # Pygments ���g���ăn�C���C�g����
      if @config['pygments']
        HParser::Block::SuperPre::use_pygments = true
      end

      parser = HParser::Parser.new
      parser.parse(content).map {|e| e.to_html }.join("\n")
    end

  end
end