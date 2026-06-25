-- slidebreak.lua
-- A Quarto shortcode that inserts a slide break in revealjs and powerpoint formats
-- but does nothing in docx and html formats

function slidebreak()
  -- Get the current output format
  local format = quarto.doc.is_format
  
  -- Insert slide break for revealjs and powerpoint/pptx formats
  if format("revealjs") or format("pptx") or format("powerpoint") then
    -- Use HorizontalRule which creates a slide separator in RevealJS
    return pandoc.HorizontalRule()
  end
  
  -- Return empty for html and docx formats (and any other format)
  return pandoc.Null()
end

-- Return the shortcode handler
return {
  ['slidebreak'] = slidebreak
}
