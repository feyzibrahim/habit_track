import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common';
import { WaitlistService } from './waitlist.service';

@Controller('waitlist')
export class WaitlistController {
  constructor(private readonly waitlistService: WaitlistService) {}

  @Post()
  async joinWaitlist(@Body('email') email: string) {
    if (!email) {
      throw new HttpException('Email is required', HttpStatus.BAD_REQUEST);
    }
    await this.waitlistService.joinWaitlist(email);
    return { message: 'Successfully joined waitlist' };
  }
}
