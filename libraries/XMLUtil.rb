require 'libxml'

class XMLUtil

    def self.parseString(str)
        include LibXML
        return XML::Document.string(str)

    end


    def self.parseFile(file)
        include LibXML
        return XML::Document.file(file)

    end

    def self.saveFile(document, file)
        include LibXML
        document.save(file, :indent => true, :encoding => XML::Encoding::UTF_8)
    end

    def self.replaceContent(document, dst, src)
        include LibXML

        # Remove all elements from destination node
        dst.each_element  do |elm|
            elm.remove!
        end

        # Copy all elements from source to destination
        src.each_element  do |elm|
            dst << document.import(elm)
        end
    end


    def self.appendNode(document, node)
        include LibXML
        document.root << document.import(node)
        return document
    end

end
