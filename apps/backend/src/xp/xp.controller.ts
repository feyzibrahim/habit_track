import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { XpService } from './xp.service';

@Controller('xp')
@UseGuards(JwtAuthGuard)
export class XpController {
  constructor(private readonly xpService: XpService) {}

  @Get('history')
  async getXpHistory(@Request() req) {
    return this.xpService.getXpHistory(req.user.id);
  }
}
