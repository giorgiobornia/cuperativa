#file: points_shower_gfx.rb

##
# Holds information about points shower
class PointsShowerGfx
  attr_accessor :pos_x, :pos_y,  :visible, :z_order, :image
  
  def initialize(x=0, y=0, img=nil, zord=0, visb=true)
    @pos_x = x       # x position
    @pos_y = y       # y position
    @image = img     # image
    @visible = visb  # visible flag
    @z_order = zord
    @text_col = nil
    @font = nil
    @team_1_name = ""
    @team_2_name = ""
    @tot_segni = 0
    @team_1_segni = 0
    @team_2_segni = 0
  end
  
  ##
  # Set names of two team
  def set_name_teams(t1_name, t2_name, font, color)
    @text_col = color
    @font = font
    @team_1_name = t1_name
    @team_2_name = t2_name
  end
  
  ##
  # Set current game pints info
  def set_segni_info(tot_segni, segn_team1, segn_team2)
    @tot_segni =  tot_segni
    @team_1_segni = segn_team1
    @team_2_segni = segn_team2
  end
  
  ##
  # Draw points
  def draw_points(dc)
    # draw background
    #control_width = @image.width
    #dc.drawImage(@image, @pos_x, @pos_y)
    # draw names
    return unless @visible
    dc.font = @font
    dc.foreground = @text_col
    width_text_1   = @font.getTextWidth(@team_1_name)
    height_text_1  = @font.getTextHeight(@team_1_name) 
    width_text_2   = @font.getTextWidth(@team_2_name)
    height_text_2  = @font.getTextHeight(@team_2_name) 
    
    control_width = width_text_1 + width_text_2 + 40
    control_height = 150
    
    # total segni
    # horizontal under names
    y1 = @pos_y + height_text_1 + 10
    y0 = y1
    x0 = @pos_x + 20
    x1 = x0 + control_width
    #dc.drawLine(x0,y0,x1,y1)
    
    # middle vertical
    xv0 = x0 + (x1 - x0)/2
    xv1 = xv0
    yv0 = y1
    yv1 = @pos_y + control_height - 2
    if @tot_segni == 2
      yv1 = yv0 + 45
    end
    dc.drawLine(xv0,yv0,xv1,yv1)
    
    #team 1 text
    #xpos_text = @pos_x + ( (control_width / 2 - 20) - width_text) / 2
    xpos_text = xv0 - 10 - width_text_1
    ypos_text = @pos_y + height_text_1
    dc.drawText(xpos_text,  ypos_text, @team_1_name)
    #team 2 text
    #xpos_text = control_width / 2 + @pos_x + ( (control_width / 2 ) - width_text) / 2
    xpos_text = xv0 + 10
    ypos_text = @pos_y + height_text_1
    dc.drawText(xpos_text,  ypos_text, @team_2_name)
    
    # empty points raggi
    #y_space_av = yv1 - yv0
    #off_y =  y_space_av / @tot_segni
    off_y =  18
    points_coord = [] # store coordinate for circle
    (0...@tot_segni).each do |ix|
      xs0 = x0 + 15
      xs1 = x1 - 15
      ys0 = off_y * ix + yv0 + 8
      ys1 = ys0
      points_coord << {:team1 => [xs0, ys0], :team2 => [xs1, ys1]} 
      dc.drawLine(xs0,ys0,xs1,ys1)
    end
    
    # draw segni as circle at the end of raggi
    count_coord = 1
    w_circle = 13
    points_coord.each do |coord_pt|
      if @team_1_segni >= count_coord
        # enable segno
        pt = coord_pt[:team1]
        fill_circle(dc, pt[0] - w_circle/2, pt[1] - w_circle/2, w_circle, w_circle)
      end
      if @team_2_segni >= count_coord
        # enable segno
        pt = coord_pt[:team2]
        fill_circle(dc, pt[0] - w_circle/2, pt[1] - w_circle/2, w_circle, w_circle)
      end
      count_coord += 1
    end
    
  end#end draw_points
  
  ##
  # Need to implement a function that draw a filled circle. fillEllipse don't exist
  def fill_circle(dc,x,y,w,h)
    dc.fillArc(x, y, w, w, 0, 64*90)
    dc.fillArc(x, y, w, w, 64*90, 64*180)
    dc.fillArc(x, y, w, w, 64*180, 64*270)
    dc.fillArc(x, y, w, w, 64*270, 64*360)
  end

end
