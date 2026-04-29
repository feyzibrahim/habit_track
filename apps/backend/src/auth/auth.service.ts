import { Injectable, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService
  ) {}

  async validateUser(email: string, pass: string): Promise<any> {
    const user = await this.usersService.findByEmail(email);
    if (user && await bcrypt.compare(pass, user.passwordHash)) {
      const { passwordHash, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user: any) {
    const payload = { email: user.email, sub: user.id };
    return {
      access_token: this.jwtService.sign(payload),
    };
  }

  async register(email: string, pass: string, firstName?: string, lastName?: string) {
    const existing = await this.usersService.findByEmail(email);
    if (existing) {
      throw new BadRequestException('User already exists. Please login.');
    }
    const hash = await bcrypt.hash(pass, 10);
    const user = await this.usersService.create(email, hash, firstName, lastName);
    return this.login(user); // auto-login after register
  }

  async registerGuest() {
    const user = await this.usersService.createGuest();
    return this.login(user);
  }

  async upgradeGuest(userId: string, email: string, pass: string, firstName?: string, lastName?: string) {
    const hash = await bcrypt.hash(pass, 10);
    const user = await this.usersService.upgradeGuest(userId, email, hash, firstName, lastName);
    return this.login(user);
  }
}
